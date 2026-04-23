import crypto from 'node:crypto';

import { config } from './config.js';
import {
  buildGeneralSystemInstruction,
  buildPdfSystemInstruction,
  buildPdfUserPrompt,
  buildQuizExplanationSystemInstruction,
  buildQuizExplanationUserPrompt,
  buildQuizSystemInstruction,
  buildQuizUserPrompt,
  generalSuggestedPrompts,
  pdfSuggestedPrompts,
  quizExplanationSuggestedPrompts,
} from './prompts.js';
import { selectCoverageChunks, selectRelevantChunks } from './pdf-context.js';
import { quizResponseSchema, validateQuizCounts } from './validators.js';

let lastHealthStatus;

const HEALTH_CACHE_TTL_MS = 60000;

export class GroqServiceError extends Error {
  constructor(details, { statusCode = 503 } = {}) {
    super('Groq API not configured or failed');
    this.name = 'GroqServiceError';
    this.details = details;
    this.statusCode = statusCode;
  }
}

function logInfo(scope, payload) {
  console.log(`[groq:${scope}]`, payload);
}

function logError(scope, error, extra = {}) {
  console.error(`[groq:${scope}]`, {
    ...extra,
    name: error?.name,
    message: error?.message,
    details: error?.details,
    statusCode: error?.statusCode,
    stack: error?.stack,
  });
}

function ensureGroqConfigured() {
  if (!config.groqConfigured) {
    if (config.groqKeyStatus === 'placeholder') {
      throw new GroqServiceError(
        'Groq API key is still set to a placeholder value in backend/.env',
      );
    }

    throw new GroqServiceError('missing API key');
  }
}

function mapHistoryToMessages(history) {
  return history.map((message) => ({
    role: message.role,
    content: message.text,
  }));
}

function extractGroqErrorDetails(error) {
  if (error instanceof GroqServiceError) {
    return error.details;
  }

  if (
    typeof error?.message === 'string' &&
    error.message.trim().length > 0
  ) {
    return error.message.trim();
  }

  return 'request failed';
}

function normalizeJsonText(text) {
  const trimmed = text.trim();
  if (trimmed.length === 0) {
    return trimmed;
  }

  const fencedMatch = trimmed.match(/^```(?:json)?\s*([\s\S]*?)\s*```$/i);
  if (fencedMatch != null) {
    return fencedMatch[1].trim();
  }

  const firstBrace = trimmed.indexOf('{');
  const lastBrace = trimmed.lastIndexOf('}');
  if (firstBrace >= 0 && lastBrace > firstBrace) {
    return trimmed.slice(firstBrace, lastBrace + 1);
  }

  return trimmed;
}

function parseJsonText(text) {
  try {
    return JSON.parse(normalizeJsonText(text));
  } catch (error) {
    throw new GroqServiceError(
      `Groq returned invalid JSON. ${error.message}`,
      { statusCode: 502 },
    );
  }
}

function isRetriableError(error) {
  const message = extractGroqErrorDetails(error).toLowerCase();
  return (
    message.includes('429') ||
    message.includes('503') ||
    message.includes('rate limit') ||
    message.includes('too many requests') ||
    message.includes('timeout') ||
    message.includes('temporarily unavailable')
  );
}

async function withRetry(operation, maxAttempts = 3) {
  let lastError;

  for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
    try {
      return await operation();
    } catch (error) {
      lastError = error;
      if (attempt >= maxAttempts || !isRetriableError(error)) {
        throw error;
      }

      const delayMs = 500 * attempt;
      await new Promise((resolve) => setTimeout(resolve, delayMs));
    }
  }

  throw lastError;
}

function wrapGroqError(error, { scope, statusCode = 503, extra = {} } = {}) {
  if (error instanceof GroqServiceError) {
    logError(scope, error, extra);
    return error;
  }

  const details = extractGroqErrorDetails(error);
  logError(scope, error, extra);
  return new GroqServiceError(details, { statusCode });
}

function buildAssistantResponse({
  requestId,
  mode,
  model,
  message,
  citations = [],
  suggestedPrompts = [],
}) {
  return {
    requestId,
    mode,
    model,
    message,
    citations,
    suggested_prompts: suggestedPrompts,
  };
}

async function requestGroqChat({
  model,
  messages,
  temperature,
  maxTokens,
  responseFormat,
}) {
  ensureGroqConfigured();

  let response;

  try {
    response = await fetch(`${config.groqBaseUrl}/chat/completions`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${config.groqApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model,
        messages,
        temperature,
        max_tokens: maxTokens,
        ...(responseFormat == null
          ? {}
          : { response_format: responseFormat }),
      }),
    });
  } catch (_error) {
    throw new GroqServiceError('Could not connect to Groq.', {
      statusCode: 503,
    });
  }

  const rawText = await response.text();
  let jsonBody = {};

  if (rawText.trim().length > 0) {
    try {
      jsonBody = JSON.parse(rawText);
    } catch (_error) {
      jsonBody = {};
    }
  }

  if (!response.ok) {
    const details =
      jsonBody?.error?.message?.trim() ||
      rawText.trim() ||
      `Groq request failed with status ${response.status}.`;
    throw new GroqServiceError(details, { statusCode: response.status });
  }

  const message = jsonBody?.choices?.[0]?.message?.content;
  if (typeof message !== 'string' || message.trim().length === 0) {
    throw new GroqServiceError('Groq returned an empty response.', {
      statusCode: 502,
    });
  }

  return {
    requestId: typeof jsonBody.id === 'string' ? jsonBody.id : crypto.randomUUID(),
    model: typeof jsonBody.model === 'string' ? jsonBody.model : model,
    text: message.trim(),
  };
}

export async function getGroqHealthStatus({ forceRefresh = false } = {}) {
  if (!config.groqConfigured) {
    const details = config.groqKeyStatus === 'placeholder'
      ? 'Groq API key is still set to a placeholder value in backend/.env'
      : 'Groq API key not configured';

    return {
      backendReachable: true,
      groqConfigured: false,
      groqWorking: false,
      details,
      chatModel: config.chatModel,
      quizModel: config.quizModel,
      provider: 'groq',
    };
  }

  const now = Date.now();
  if (
    !forceRefresh &&
    lastHealthStatus != null &&
    now - lastHealthStatus.checkedAt < HEALTH_CACHE_TTL_MS
  ) {
    return lastHealthStatus.value;
  }

  try {
    const response = await withRetry(() =>
      requestGroqChat({
        model: config.chatModel,
        messages: [
          { role: 'system', content: 'Reply with OK only.' },
          { role: 'user', content: 'Reply with OK only.' },
        ],
        temperature: 0.1,
        maxTokens: 8,
      }),
    );

    const value = {
      backendReachable: true,
      groqConfigured: true,
      groqWorking: response.text.length > 0,
      details: response.text.length > 0
        ? 'Groq is connected and responding normally.'
        : 'Groq returned an empty response during health check.',
      chatModel: config.chatModel,
      quizModel: config.quizModel,
      provider: 'groq',
    };

    lastHealthStatus = {
      checkedAt: now,
      value,
    };

    return value;
  } catch (error) {
    const details = extractGroqErrorDetails(error);
    logError('health-check', error);
    const value = {
      backendReachable: true,
      groqConfigured: true,
      groqWorking: false,
      details,
      chatModel: config.chatModel,
      quizModel: config.quizModel,
      provider: 'groq',
    };

    lastHealthStatus = {
      checkedAt: now,
      value,
    };

    return value;
  }
}

export async function generateGeneralChat(payload) {
  const requestId = crypto.randomUUID();
  logInfo('chat/general.request', {
    requestId,
    model: config.chatModel,
    historyLength: payload.history.length,
    messagePreview: payload.message.slice(0, 120),
  });

  try {
    const response = await withRetry(() =>
      requestGroqChat({
        model: config.chatModel,
        messages: [
          {
            role: 'system',
            content: buildGeneralSystemInstruction(),
          },
          ...mapHistoryToMessages(payload.history),
          {
            role: 'user',
            content: payload.message,
          },
        ],
        temperature: 0.7,
        maxTokens: 900,
      }),
    );

    logInfo('chat/general.response', {
      requestId,
      responsePreview: response.text.slice(0, 120),
    });

    return buildAssistantResponse({
      requestId,
      mode: 'general',
      model: response.model,
      message: response.text,
      citations: [],
      suggestedPrompts: generalSuggestedPrompts,
    });
  } catch (error) {
    throw wrapGroqError(error, {
      scope: 'chat/general',
      extra: { requestId },
    });
  }
}

export async function generatePdfChat(payload) {
  const requestId = crypto.randomUUID();
  const fileName =
    payload.fileName ??
    payload.file_name ??
    payload.document?.file_name ??
    'Uploaded PDF';
  const pdfText = payload.pdfText ?? payload.document?.text ?? '';
  const relevantChunks = selectRelevantChunks(
    pdfText,
    payload.message,
    config.pdfContextMaxChars,
  );

  logInfo('chat/pdf.request', {
    requestId,
    model: config.chatModel,
    fileName,
    historyLength: payload.history.length,
    messagePreview: payload.message.slice(0, 120),
    chunkCount: relevantChunks.length,
  });

  try {
    const response = await withRetry(() =>
      requestGroqChat({
        model: config.chatModel,
        messages: [
          {
            role: 'system',
            content: buildPdfSystemInstruction({
              fileName,
              actionType: payload.action_type,
            }),
          },
          ...mapHistoryToMessages(payload.history),
          {
            role: 'user',
            content: buildPdfUserPrompt({
              fileName,
              message: payload.message,
              actionType: payload.action_type,
              relevantChunks,
            }),
          },
        ],
        temperature: 0.4,
        maxTokens: 1100,
      }),
    );

    logInfo('chat/pdf.response', {
      requestId,
      responsePreview: response.text.slice(0, 120),
    });

    return buildAssistantResponse({
      requestId,
      mode: 'pdf',
      model: response.model,
      message: response.text,
      citations: relevantChunks,
      suggestedPrompts: pdfSuggestedPrompts,
    });
  } catch (error) {
    throw wrapGroqError(error, {
      scope: 'chat/pdf',
      extra: { requestId, fileName },
    });
  }
}

export async function generateQuiz(payload) {
  const requestId = crypto.randomUUID();
  const contextChunks = selectCoverageChunks(
    payload.pdf_text,
    config.pdfContextMaxChars,
  );

  logInfo('quiz.request', {
    requestId,
    model: config.quizModel,
    fileName: payload.source_pdf_name,
    difficulty: payload.difficulty,
    questionCounts: payload.question_counts,
    chunkCount: contextChunks.length,
  });

  try {
    const response = await withRetry(() =>
      requestGroqChat({
        model: config.quizModel,
        messages: [
          {
            role: 'system',
            content: buildQuizSystemInstruction(),
          },
          {
            role: 'user',
            content: buildQuizUserPrompt({
              fileName: payload.source_pdf_name,
              difficulty: payload.difficulty,
              questionCounts: payload.question_counts,
              contextChunks,
              userInstruction: payload.user_instruction,
            }),
          },
        ],
        temperature: 0.2,
        maxTokens: 3200,
        responseFormat: { type: 'json_object' },
      }),
    );

    const quiz = quizResponseSchema.parse(parseJsonText(response.text));
    validateQuizCounts(quiz, payload.question_counts);
    logInfo('quiz.response', {
      requestId,
      totalQuestions: quiz.total_questions,
    });

    return {
      requestId,
      mode: 'quiz',
      model: response.model,
      quiz,
    };
  } catch (error) {
    throw wrapGroqError(error, {
      scope: 'quiz',
      statusCode: 502,
      extra: { requestId, fileName: payload.source_pdf_name },
    });
  }
}

export async function generateQuizExplanation(payload) {
  const requestId = crypto.randomUUID();
  const searchText = [
    payload.quiz_context.question_prompt,
    payload.quiz_context.correct_answer,
    payload.quiz_context.user_answer,
    payload.message,
  ].filter(Boolean).join(' ');

  const relevantChunks = selectRelevantChunks(
    payload.document.text,
    searchText,
    config.pdfContextMaxChars,
  );

  logInfo('quiz/explanation.request', {
    requestId,
    model: config.chatModel,
    quizTitle: payload.quiz_context.quiz_title,
    fileName: payload.document.file_name,
    historyLength: payload.history.length,
    chunkCount: relevantChunks.length,
  });

  try {
    const response = await withRetry(() =>
      requestGroqChat({
        model: config.chatModel,
        messages: [
          {
            role: 'system',
            content: buildQuizExplanationSystemInstruction({
              fileName: payload.document.file_name,
              quizTitle: payload.quiz_context.quiz_title,
            }),
          },
          ...mapHistoryToMessages(payload.history),
          {
            role: 'user',
            content: buildQuizExplanationUserPrompt({
              fileName: payload.document.file_name,
              message: payload.message,
              questionPrompt: payload.quiz_context.question_prompt,
              correctAnswer: payload.quiz_context.correct_answer,
              userAnswer: payload.quiz_context.user_answer,
              relevantChunks,
            }),
          },
        ],
        temperature: 0.4,
        maxTokens: 900,
      }),
    );

    logInfo('quiz/explanation.response', {
      requestId,
      responsePreview: response.text.slice(0, 120),
    });

    return buildAssistantResponse({
      requestId,
      mode: 'quiz_explanation',
      model: response.model,
      message: response.text,
      citations: relevantChunks,
      suggestedPrompts: quizExplanationSuggestedPrompts,
    });
  } catch (error) {
    throw wrapGroqError(error, {
      scope: 'quiz/explanation',
      extra: {
        requestId,
        quizTitle: payload.quiz_context.quiz_title,
        fileName: payload.document.file_name,
      },
    });
  }
}

export async function respondWithAi(payload) {
  switch (payload.mode) {
    case 'general':
      return generateGeneralChat(payload);
    case 'pdf':
      return generatePdfChat(payload);
    case 'quiz':
      return generateQuiz(payload);
    case 'quiz_explanation':
      return generateQuizExplanation(payload);
    default:
      throw new GroqServiceError('Unsupported AI mode requested', {
        statusCode: 400,
      });
  }
}

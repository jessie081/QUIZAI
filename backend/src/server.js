import 'dotenv/config';
import cors from 'cors';
import express from 'express';
import { ZodError } from 'zod';

import { config } from './config.js';
import {
  getGroqHealthStatus,
  respondWithAi,
} from './groq-service.js';
import {
  aiRespondRequestSchema,
  generalChatRequestSchema,
  pdfChatRequestSchema,
  quizGenerationRequestSchema,
} from './validators.js';

const app = express();

const corsOptions = config.allowedOrigins === '*'
  ? { origin: true }
  : {
      origin: config.allowedOrigins
        .split(',')
        .map((origin) => origin.trim())
        .filter(Boolean),
    };

app.use(cors(corsOptions));
app.use(express.json({ limit: '4mb' }));

app.get('/health', async (_, res) => {
  const health = await getGroqHealthStatus({ forceRefresh: true });
  res.json({
    status: health.groqWorking ? 'ok' : 'degraded',
    provider: health.provider,
    backendReachable: health.backendReachable,
    groqConfigured: health.groqConfigured,
    groqWorking: health.groqWorking,
    details: health.details,
    chat_model: health.chatModel,
    quiz_model: health.quizModel,
  });
});

app.post('/ai/respond', async (req, res, next) => {
  const startedAt = Date.now();
  console.log('[api:/ai/respond] Incoming request', {
    mode: req.body?.mode,
  });

  try {
    const payload = aiRespondRequestSchema.parse(req.body);
    const response = await respondWithAi(payload);
    console.log('[api:/ai/respond] Success', {
      mode: payload.mode,
      requestId: response.requestId,
      durationMs: Date.now() - startedAt,
    });
    res.json(response);
  } catch (error) {
    console.error('[api:/ai/respond] Groq error:', error);
    next(error);
  }
});

app.post('/chat/general', async (req, res, next) => {
  const startedAt = Date.now();
  console.log('[api:/chat/general] Incoming request', {
    hasMessage: typeof req.body?.message === 'string',
    historyLength: Array.isArray(req.body?.history) ? req.body.history.length : 0,
  });

  try {
    const payload = generalChatRequestSchema.parse(req.body);
    const response = await respondWithAi({
      mode: 'general',
      ...payload,
    });
    console.log('[api:/chat/general] Success', {
      requestId: response.requestId,
      durationMs: Date.now() - startedAt,
    });
    res.json(response);
  } catch (error) {
    console.error('[api:/chat/general] Groq error:', error);
    next(error);
  }
});

app.post('/chat/pdf', async (req, res, next) => {
  const startedAt = Date.now();
  console.log('[api:/chat/pdf] Incoming request', {
    hasMessage: typeof req.body?.message === 'string',
    hasPdfText: typeof req.body?.pdfText === 'string',
    hasDocumentText: typeof req.body?.document?.text === 'string',
    historyLength: Array.isArray(req.body?.history) ? req.body.history.length : 0,
  });

  try {
    const payload = pdfChatRequestSchema.parse(req.body);
    const response = await respondWithAi({
      mode: 'pdf',
      ...payload,
    });
    console.log('[api:/chat/pdf] Success', {
      requestId: response.requestId,
      durationMs: Date.now() - startedAt,
    });
    res.json(response);
  } catch (error) {
    console.error('[api:/chat/pdf] Groq error:', error);
    next(error);
  }
});

app.post('/quiz/generate', async (req, res, next) => {
  const startedAt = Date.now();
  try {
    const payload = quizGenerationRequestSchema.parse(req.body);
    const response = await respondWithAi({
      mode: 'quiz',
      ...payload,
    });
    console.log('[api:/quiz/generate] Success', {
      requestId: response.requestId,
      durationMs: Date.now() - startedAt,
    });
    res.json(response);
  } catch (error) {
    console.error('[api:/quiz/generate] Groq error:', error);
    next(error);
  }
});

app.use((error, _req, res, _next) => {
  if (error instanceof ZodError) {
    res.status(400).json({
      error: 'Request validation failed.',
      details: error.flatten(),
    });
    return;
  }

  const message = error instanceof Error ? error.message : 'Unexpected server error.';
  const details =
    typeof error?.details === 'string' && error.details.trim().length > 0
      ? error.details.trim()
      : message;
  const normalizedMessage = message.toLowerCase();
  let statusCode = typeof error?.statusCode === 'number' ? error.statusCode : 500;
  if (
    normalizedMessage.includes('invalid json') ||
    normalizedMessage.includes('wrong number')
  ) {
    statusCode = 502;
  } else if (
    normalizedMessage.includes('groq api key') ||
    normalizedMessage.includes('groq api not configured or failed')
  ) {
    statusCode = 503;
  }

  res.status(statusCode).json({
    error:
      normalizedMessage.includes('groq')
        ? 'Groq API not configured or failed'
        : message,
    details,
  });
});

app.listen(config.port, '0.0.0.0', () => {
  console.log(`Server running on http://localhost:${config.port}`);
  if (config.groqKeyStatus === 'configured') {
    const maskedKey =
      `${config.groqApiKey.slice(0, 4)}...${config.groqApiKey.slice(-4)}`;
    console.log('Groq key loaded:', maskedKey);
  } else if (config.groqKeyStatus === 'placeholder') {
    console.log('Groq key loaded: placeholder value detected');
  } else {
    console.log('Groq key loaded:', false);
  }

  void getGroqHealthStatus({ forceRefresh: true }).then((health) => {
    if (health.groqWorking) {
      console.log(
        `Groq connected. Chat model: ${config.chatModel}. Quiz model: ${config.quizModel}.`,
      );
      return;
    }

    if (config.groqKeyStatus === 'placeholder') {
      console.log(
        'Groq check failed: GROQ_API_KEY in backend/.env is still a placeholder. Replace it with your real Groq API key, then restart the backend.',
      );
      return;
    }

    if (config.groqKeyStatus === 'missing') {
      console.log(
        'Groq check failed: GROQ_API_KEY is missing from backend/.env. Add it and restart the backend.',
      );
      return;
    }

    console.log(`Groq check failed: ${health.details}`);
  });
});

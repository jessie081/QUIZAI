import { z } from 'zod';

const historyItemSchema = z.object({
  role: z.enum(['user', 'assistant']),
  text: z.string().trim().min(1).max(6000),
});

const documentContextSchema = z.object({
  id: z.string().trim().min(1),
  file_name: z.string().trim().min(1),
  text: z.string().trim().min(1),
  word_count: z.number().int().nonnegative().optional(),
  excerpt: z.string().optional(),
});

const generalChatPayloadSchema = z.object({
  message: z.string().trim().min(1).max(6000),
  action_type: z.string().trim().min(1).max(60).default('ask'),
  history: z.array(historyItemSchema).max(20).default([]),
});

export const generalChatRequestSchema = generalChatPayloadSchema;

const pdfChatPayloadShape = {
  message: z.string().trim().min(1).max(6000),
  action_type: z.string().trim().min(1).max(60).default('ask'),
  history: z.array(historyItemSchema).max(20).default([]),
  pdfText: z.string().trim().min(1).max(500000).optional(),
  fileName: z.string().trim().min(1).max(255).optional(),
  file_name: z.string().trim().min(1).max(255).optional(),
  document: documentContextSchema.optional(),
};

function validatePdfChatPayload(value, ctx) {
  const hasPdfText =
    (typeof value.pdfText === 'string' && value.pdfText.trim().length > 0) ||
    (typeof value.document?.text === 'string' &&
      value.document.text.trim().length > 0);

  if (!hasPdfText) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: 'PDF mode requires pdfText or document.text.',
      path: ['pdfText'],
    });
  }
}

const pdfChatPayloadSchema = z
  .object(pdfChatPayloadShape)
  .superRefine(validatePdfChatPayload);

export const pdfChatRequestSchema = pdfChatPayloadSchema;

const questionCountsSchema = z.object({
  multiple_choice: z.number().int().min(0).max(50),
  true_false: z.number().int().min(0).max(50),
  identification: z.number().int().min(0).max(50),
  short_answer: z.number().int().min(0).max(50),
}).refine(
  (value) =>
    value.multiple_choice +
      value.true_false +
      value.identification +
      value.short_answer >
    0,
  {
    message: 'At least one question must be requested.',
  },
);

const quizGenerationPayloadSchema = z.object({
  source_pdf_id: z.string().trim().min(1),
  source_pdf_name: z.string().trim().min(1),
  pdf_text: z.string().trim().min(1),
  difficulty: z.enum(['easy', 'medium', 'hard']),
  question_counts: questionCountsSchema,
  user_instruction: z.string().trim().max(1000).optional(),
});

export const quizGenerationRequestSchema = quizGenerationPayloadSchema;

export const quizExplanationRequestSchema = z.object({
  message: z.string().trim().max(6000).optional(),
  action_type: z.string().trim().min(1).max(60).default('explainQuizAnswer'),
  history: z.array(historyItemSchema).max(20).default([]),
  document: documentContextSchema,
  quiz_context: z.object({
    quiz_title: z.string().trim().min(1),
    question_prompt: z.string().trim().min(1),
    correct_answer: z.string().trim().min(1),
    user_answer: z.string().trim().optional(),
  }),
});

export const aiRespondRequestSchema = z.union([
  generalChatPayloadSchema.extend({
    mode: z.literal('general'),
  }),
  z
    .object({
      mode: z.literal('pdf'),
      ...pdfChatPayloadShape,
    })
    .superRefine(validatePdfChatPayload),
  quizGenerationPayloadSchema.extend({
    mode: z.literal('quiz'),
  }),
  quizExplanationRequestSchema.extend({
    mode: z.literal('quiz_explanation'),
  }),
]);

const quizQuestionSchema = z.object({
  type: z.enum([
    'multiple_choice',
    'true_false',
    'identification',
    'short_answer',
  ]),
  question: z.string().trim().min(1),
  options: z.array(z.string().trim().min(1)).optional(),
  answer: z.string().trim().min(1),
});

export const quizResponseSchema = z.object({
  quiz_title: z.string().trim().min(1),
  difficulty: z.enum(['easy', 'medium', 'hard']),
  question_counts: z.object({
    multiple_choice: z.number().int().min(0),
    true_false: z.number().int().min(0),
    identification: z.number().int().min(0),
    short_answer: z.number().int().min(0),
  }),
  total_questions: z.number().int().min(1),
  questions: z.array(quizQuestionSchema).min(1),
});

export function validateQuizCounts(quiz, requestedCounts) {
  const actualCounts = {
    multiple_choice: 0,
    true_false: 0,
    identification: 0,
    short_answer: 0,
  };

  for (const question of quiz.questions) {
    actualCounts[question.type] += 1;

    if (question.type === 'multiple_choice') {
      if (!Array.isArray(question.options) || question.options.length !== 4) {
        throw new Error('Multiple choice questions must include exactly 4 options.');
      }
    }

    if (question.type !== 'multiple_choice' && question.options) {
      if (question.options.length > 0) {
        throw new Error('Only multiple choice questions may include options.');
      }
    }
  }

  const requestedTotal =
    requestedCounts.multiple_choice +
    requestedCounts.true_false +
    requestedCounts.identification +
    requestedCounts.short_answer;

  if (quiz.total_questions !== requestedTotal) {
    throw new Error('Groq returned the wrong total question count.');
  }

  if (quiz.questions.length !== requestedTotal) {
    throw new Error('Groq returned a question array with the wrong length.');
  }

  for (const [type, count] of Object.entries(requestedCounts)) {
    if (actualCounts[type] !== count) {
      throw new Error(`Groq returned the wrong number of ${type} questions.`);
    }
  }
}

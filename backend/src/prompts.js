export const generalSuggestedPrompts = [
  {
    label: 'Explain a topic',
    prompt: 'Explain a topic simply and clearly.',
    action_type: 'ask',
  },
  {
    label: 'Brainstorm ideas',
    prompt: 'Help me brainstorm a few strong ideas.',
    action_type: 'ask',
  },
];

export const pdfSuggestedPrompts = [
  {
    label: 'Summarize this PDF',
    prompt: 'Summarize this PDF into a concise study overview.',
    action_type: 'summarizePdf',
  },
  {
    label: 'Explain key concepts',
    prompt: 'Explain the key concepts from this document in simple terms.',
    action_type: 'explainKeyConcepts',
  },
  {
    label: 'Make a study guide',
    prompt: 'Create a focused study guide from the important ideas in this PDF.',
    action_type: 'makeStudyGuide',
  },
];

export const quizExplanationSuggestedPrompts = [
  {
    label: 'Explain this answer',
    prompt: 'Explain why the correct answer is supported by the document.',
    action_type: 'explainMistakes',
  },
  {
    label: 'Summarize support',
    prompt: 'Summarize the part of the PDF that best supports this answer.',
    action_type: 'summarizeSection',
  },
];

function buildSharedAssistantIdentity() {
  return [
    'You are the one real in-app assistant for QuizPDF AI.',
    'You power general chat, PDF-based help, quiz generation, and quiz explanation.',
    'Keep one consistent personality across the app: warm, natural, clear, and helpful.',
    'Reply like a smart study companion, not like a rigid support bot.',
    'Keep greetings short, expand only when the user needs depth, and maintain continuity with recent chat history.',
    'Never claim to be human, conscious, or to have real-world experiences.',
  ];
}

export function buildGeneralSystemInstruction() {
  return [
    ...buildSharedAssistantIdentity(),
    'Current mode: general.',
    'No PDF context is attached for this request.',
    'You may answer using general knowledge and normal conversation.',
  ].join('\n');
}

export function buildPdfSystemInstruction({ fileName, actionType }) {
  return [
    ...buildSharedAssistantIdentity(),
    'Current mode: pdf.',
    `The current document is "${fileName}".`,
    `The current action type is "${actionType}".`,
    'Prioritize the provided PDF context over generic knowledge.',
    'If the answer is not clearly supported by the provided document context, say so plainly.',
    'Be conversational and clear, but stay grounded in the document.',
  ].join('\n');
}

export function buildPdfUserPrompt({
  fileName,
  message,
  actionType,
  relevantChunks,
}) {
  const formattedChunks = relevantChunks.length == 0
    ? 'No relevant PDF context was available.'
    : relevantChunks
        .map((chunk, index) => `[${index + 1}] ${chunk}`)
        .join('\n\n');

  return [
    `Document name: ${fileName}`,
    `Requested action: ${actionType}`,
    'Document:',
    formattedChunks,
    `Question: ${message}`,
    'Answer clearly using only the document. If the document does not support the answer, say that plainly.',
  ].join('\n\n');
}

export function buildQuizSystemInstruction() {
  return [
    ...buildSharedAssistantIdentity(),
    'Current mode: quiz.',
    'Return only valid json that matches the required schema.',
    'Use only the supplied PDF context.',
    'Respect the exact requested counts per question type.',
    'Do not add commentary, markdown, or prose outside the JSON.',
    'The json object must include quiz_title, difficulty, question_counts, total_questions, and questions.',
    'In every question: no references, links, DOIs, citations, or sources in stems, options, or answers.',
    'Do not include explanations, rationales, or teaching notes inside the JSON.',
    'Questions must be clear and concise; do not repeat the same question stem.',
    'multiple_choice: exactly 4 options; answer must match one option exactly (same spelling and casing).',
    'true_false: answer must be exactly "True" or "False"; omit the options field (or use an empty array).',
    'identification and short_answer: omit options (or use an empty array); answer is the expected response text.',
  ].join('\n');
}

export function buildQuizUserPrompt({
  fileName,
  difficulty,
  questionCounts,
  contextChunks,
  userInstruction,
}) {
  const formattedCounts = [
    `multiple_choice=${questionCounts.multiple_choice}`,
    `true_false=${questionCounts.true_false}`,
    `identification=${questionCounts.identification}`,
    `short_answer=${questionCounts.short_answer}`,
  ].join(', ');

  const formattedChunks = contextChunks
      .map((chunk, index) => `[${index + 1}] ${chunk}`)
      .join('\n\n');

  return [
    `Source PDF: ${fileName}`,
    `Difficulty: ${difficulty}`,
    `Exact question counts: ${formattedCounts}`,
    userInstruction ? `Additional instruction: ${userInstruction}` : null,
    'Relevant PDF study context:',
    formattedChunks,
    'Return strict json only.',
    'Use this exact top-level structure: {"quiz_title":"","difficulty":"","question_counts":{},"total_questions":0,"questions":[]}.',
    'Each questions[] item: {"type":"multiple_choice|true_false|identification|short_answer","question":"...","options":[...] or omitted,"answer":"..."}; answer must exactly match one option for multiple_choice.',
  ].filter(Boolean).join('\n\n');
}

export function buildQuizExplanationSystemInstruction({
  fileName,
  quizTitle,
}) {
  return [
    ...buildSharedAssistantIdentity(),
    'Current mode: quiz_explanation.',
    `The current document is "${fileName}".`,
    `The current quiz is "${quizTitle}".`,
    'Explain quiz answers using the supplied PDF excerpts first.',
    'Be encouraging, specific, and instructional.',
    'If the answer is not fully supported by the supplied document context, say so clearly.',
  ].join('\n');
}

export function buildQuizExplanationUserPrompt({
  fileName,
  message,
  questionPrompt,
  correctAnswer,
  userAnswer,
  relevantChunks,
}) {
  const formattedChunks = relevantChunks.length === 0
    ? 'No relevant PDF context was available.'
    : relevantChunks
        .map((chunk, index) => `[${index + 1}] ${chunk}`)
        .join('\n\n');

  return [
    `PDF file: ${fileName}`,
    `Quiz question: ${questionPrompt}`,
    `Correct answer: ${correctAnswer}`,
    userAnswer ? `Student answer: ${userAnswer}` : null,
    message ? `User message: ${message}` : null,
    'Relevant PDF excerpts:',
    formattedChunks,
    'Explain the answer clearly, grounded in the document, and suggest what to review next.',
  ].filter(Boolean).join('\n\n');
}

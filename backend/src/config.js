import dotenv from 'dotenv';

dotenv.config();

const placeholderPatterns = [
  /^your[_-]?api[_-]?key[_-]?here$/,
  /^your[_-]?groq[_-]?api[_-]?key[_-]?here$/,
  /^your[_-]?actual[_-]?api[_-]?key[_-]?here$/,
  /^real[_-]?groq[_-]?api[_-]?key[_-]?here$/,
  /^replace(_with)?[_-]?your[_-]?real[_-]?groq[_-]?api[_-]?key$/,
  /^replace[_-]?me$/,
  /^placeholder$/,
];

function getStringEnv(name, fallback = '') {
  return process.env[name]?.trim() || fallback;
}

function getNumberEnv(name, fallback) {
  const rawValue = process.env[name];
  if (!rawValue) {
    return fallback;
  }

  const parsed = Number(rawValue);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function getGroqKeyStatus(value) {
  const normalized = value.trim().toLowerCase();
  if (normalized.length === 0) {
    return 'missing';
  }

  const compact = normalized.replace(/\s+/g, '');
  const isPlaceholder = placeholderPatterns.some((pattern) => pattern.test(compact));
  if (
    isPlaceholder ||
    compact.includes('placeholder') ||
    compact.includes('replace_me') ||
    compact.includes('your_api_key_here')
  ) {
    return 'placeholder';
  }

  return 'configured';
}

const groqApiKey = getStringEnv('GROQ_API_KEY');
const groqKeyStatus = getGroqKeyStatus(groqApiKey);

export const config = {
  port: getNumberEnv('PORT', 8080),
  groqApiKey,
  groqConfigured: groqKeyStatus === 'configured',
  groqKeyStatus,
  groqBaseUrl: getStringEnv('GROQ_BASE_URL', 'https://api.groq.com/openai/v1'),
  chatModel: getStringEnv('GROQ_CHAT_MODEL', 'llama-3.3-70b-versatile'),
  quizModel: getStringEnv('GROQ_QUIZ_MODEL', 'llama-3.3-70b-versatile'),
  allowedOrigins: getStringEnv('ALLOWED_ORIGINS', '*'),
  pdfContextMaxChars: getNumberEnv('PDF_CONTEXT_MAX_CHARS', 6000),
};

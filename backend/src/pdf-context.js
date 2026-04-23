function normalizeText(text) {
  return text.replace(/\r\n/g, '\n').trim();
}

function splitIntoChunks(text) {
  return normalizeText(text)
    .split(/\n{2,}|(?<=\.)\s+/)
    .map((chunk) => chunk.trim())
    .filter((chunk) => chunk.length >= 40);
}

function scoreChunk(chunk, terms) {
  const lowerChunk = chunk.toLowerCase();
  return terms.reduce((score, term) => {
    if (!lowerChunk.includes(term)) {
      return score;
    }
    return score + 1;
  }, 0);
}

function queryTerms(query) {
  return query
    .toLowerCase()
    .split(/[^a-z0-9]+/)
    .filter((term) => term.length > 2);
}

function trimChunk(chunk, maxLength = 700) {
  if (chunk.length <= maxLength) {
    return chunk;
  }
  return `${chunk.slice(0, maxLength).trim()}...`;
}

export function selectRelevantChunks(text, query, maxChars) {
  const chunks = splitIntoChunks(text);
  if (chunks.length === 0) {
    return [];
  }

  const terms = queryTerms(query);
  const ranked = [...chunks].sort((a, b) => scoreChunk(b, terms) - scoreChunk(a, terms));

  const selected = [];
  let totalChars = 0;

  for (const chunk of ranked) {
    const trimmed = trimChunk(chunk);
    if (totalChars + trimmed.length > maxChars && selected.length > 0) {
      continue;
    }

    selected.push(trimmed);
    totalChars += trimmed.length;

    if (selected.length >= 6 || totalChars >= maxChars) {
      break;
    }
  }

  return selected.length > 0 ? selected : ranked.slice(0, 3).map((chunk) => trimChunk(chunk));
}

export function selectCoverageChunks(text, maxChars) {
  const chunks = splitIntoChunks(text);
  if (chunks.length === 0) {
    return [];
  }

  const step = Math.max(1, Math.floor(chunks.length / 6));
  const selected = [];
  let totalChars = 0;

  for (let index = 0; index < chunks.length; index += step) {
    const trimmed = trimChunk(chunks[index]);
    if (totalChars + trimmed.length > maxChars && selected.length > 0) {
      break;
    }

    selected.push(trimmed);
    totalChars += trimmed.length;

    if (selected.length >= 6 || totalChars >= maxChars) {
      break;
    }
  }

  return selected.length > 0 ? selected : chunks.slice(0, 3).map((chunk) => trimChunk(chunk));
}

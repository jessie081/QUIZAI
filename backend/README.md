# QuizPDF AI Backend

Node/Express backend that securely calls Groq for:

- `POST /ai/respond`
- `POST /chat/general`
- `POST /chat/pdf`
- `POST /quiz/generate`

The legacy routes are still available, but the app now uses one shared Groq-powered assistant across chat, PDF help, quiz generation, and quiz explanation.

## Setup

1. Copy `.env.example` to `.env`
2. Add your real Groq API key
3. Install dependencies
4. Start the server

```bash
cd backend
npm install
npm run dev
```

## Environment Variables

```env
PORT=8080
GROQ_API_KEY=YOUR_GROQ_API_KEY_HERE
GROQ_CHAT_MODEL=llama-3.3-70b-versatile
GROQ_QUIZ_MODEL=llama-3.3-70b-versatile
GROQ_BASE_URL=https://api.groq.com/openai/v1
ALLOWED_ORIGINS=*
PDF_CONTEXT_MAX_CHARS=6000
```

## Flutter Connection

Point the Flutter app at the backend with a dart define:

```bash
flutter run --dart-define=QUIZPDF_API_BASE_URL=http://10.0.2.2:8080
```

Use `10.0.2.2` for the Android emulator. Use your machine IP for a real device.

## Request Examples

### `POST /ai/respond` general mode

```json
{
  "mode": "general",
  "message": "Explain black holes simply.",
  "action_type": "ask",
  "history": [
    { "role": "user", "text": "hey" },
    { "role": "assistant", "text": "Hey. What's up?" }
  ]
}
```

### `POST /ai/respond` pdf mode

```json
{
  "mode": "pdf",
  "message": "Summarize this document.",
  "action_type": "summarizePdf",
  "history": [],
  "fileName": "biology-reviewer.pdf",
  "pdfText": "Full extracted PDF text goes here..."
}
```

### `POST /ai/respond` quiz mode

```json
{
  "mode": "quiz",
  "source_pdf_id": "pdf-123",
  "source_pdf_name": "biology-reviewer.pdf",
  "pdf_text": "Full extracted PDF text goes here...",
  "difficulty": "medium",
  "question_counts": {
    "multiple_choice": 5,
    "true_false": 3,
    "identification": 4,
    "short_answer": 2
  },
  "user_instruction": "Focus on the most important concepts."
}
```

Sample response:

```json
{
  "requestId": "abc123",
  "mode": "quiz",
  "model": "llama-3.3-70b-versatile",
  "quiz": {
    "quiz_title": "Generated Quiz",
    "difficulty": "medium",
    "question_counts": {
      "multiple_choice": 5,
      "true_false": 3,
      "identification": 4,
      "short_answer": 2
    },
    "total_questions": 14,
    "questions": [
      {
        "type": "multiple_choice",
        "question": "Question text here",
        "options": ["A", "B", "C", "D"],
        "answer": "B"
      }
    ]
  }
}
```

## Security Notes

- Keep `GROQ_API_KEY` on the server only.
- Do not send the Groq key to Flutter.
- Restrict `ALLOWED_ORIGINS` in real deployments.
- Add auth before exposing the backend publicly.

## Retry and Rate Limits

- Endpoints are stateless and safe to retry because they do not mutate server state.
- The backend retries common transient Groq failures such as rate limiting or temporary unavailability.
- The server trims PDF context before calling Groq instead of forwarding the full document blindly when it is large.

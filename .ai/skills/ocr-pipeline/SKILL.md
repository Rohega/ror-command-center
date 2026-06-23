# ocr-pipeline

## Purpose

Design and review a production OCR pipeline in Rails: ingest documents/images, extract
text/data asynchronously, validate, and persist results with auditability.

**Use when:** building document scanning/OCR with Tesseract, AWS Textract, or Google Vision.

## Inputs

- Source of documents (upload, email, S3 drop, WhatsApp media)
- OCR engine/provider (Tesseract, AWS Textract, Google Vision, etc.)
- Expected document types and target structured fields
- `.ai/standards/sidekiq-activejob.md`, `.ai/standards/security.md`

## Outputs

- Architecture/implementation plan in `docs/architecture/` (pipeline stages, retries, storage)
- Models, jobs, and Service Objects design for ingest → extract → validate → persist

## Execution Steps

1. **Ingest** — Store original in S3 (private, encrypted); persist a `Document` record with status.
2. **Enqueue** — ActiveJob/Sidekiq job per document; pass the ID, keep jobs idempotent.
3. **Extract** — Call the OCR provider with timeout + retry/backoff; store raw output and confidence.
4. **Parse/validate** — Map raw text to structured fields; flag low-confidence for human review.
5. **Persist** — Save structured results; update document status; emit audit log.
6. **Notify** — Trigger downstream (webhook, WhatsApp, email) on completion/failure.
7. **Observe** — Track throughput, failure rate, provider latency, and cost.

## Validation Checklist

- [ ] Originals stored privately (S3, encrypted) — never in the DB as blobs
- [ ] Jobs idempotent and retry-safe; poison documents routed to a dead/review state
- [ ] Provider calls have timeouts, retries, and cost/quota limits
- [ ] Low-confidence results routed to human-in-the-loop review
- [ ] PII handling and retention policy documented (`.ai/standards/security.md`)
- [ ] Status state machine and audit trail per document

## Agent

`backend-rails-developer` (with `rails-architect` for pipeline design)

## Workflow

`.ai/workflows/new-feature.yaml` → phases `architecture` and `development`

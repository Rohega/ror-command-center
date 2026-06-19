# whatsapp-integration

## Purpose

Design and review a WhatsApp integration in Rails (WhatsApp Cloud API or a BSP like
Twilio): send/receive messages, handle templates, media, and webhooks securely and reliably.

## Inputs

- Provider (WhatsApp Cloud API, Twilio, 360dialog, etc.) and credentials scope
- Use cases: notifications, conversational flows, media (OCR handoff), support
- `.ai/standards/sidekiq-activejob.md`, `.ai/standards/security.md`, `.ai/standards/api-design.md`

## Outputs

- Integration design in `docs/architecture/` (inbound webhook, outbound jobs, data model)
- Models, jobs, and Service Objects for messaging + a verified webhook controller

## Execution Steps

1. **Webhook** — Implement verification (GET challenge) and signature validation (HMAC) on inbound POSTs.
2. **Inbound** — Persist messages; enqueue processing jobs; ACK fast (respond 200 quickly).
3. **Outbound** — Send via ActiveJob/Sidekiq with retry/backoff; respect rate limits.
4. **Templates** — Use approved message templates for business-initiated messages; track the 24h session window.
5. **Media** — Download/upload media to private S3; hand off to `ocr-pipeline` when applicable.
6. **State** — Model conversations/messages with delivery/read status updates from callbacks.
7. **Observe** — Monitor delivery rate, failures, template rejections, and quota usage.

## Validation Checklist

- [ ] Webhook signature verified; reject unsigned/invalid payloads
- [ ] Inbound processing is async and idempotent (dedupe by provider message ID)
- [ ] Outbound respects rate limits and the 24-hour session/template rules
- [ ] Secrets/tokens in a secrets manager — never in the repo or logs
- [ ] PII and message-content retention policy documented
- [ ] Delivery/read status reconciled from provider callbacks

## Agent

`backend-rails-developer` (with `security-reviewer` for webhook/secret review)

## Workflow

`.ai/workflows/new-feature.yaml` → phases `architecture` and `development`

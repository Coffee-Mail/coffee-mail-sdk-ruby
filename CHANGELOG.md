# Changelog

Todas as mudanças relevantes deste projeto são documentadas aqui. O formato segue o [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/) e o projeto adota o [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [Não lançado]

### Adicionado

- `senders.resend_verification(id)` reenvia o e-mail de verificação com token novo (RB-OPS-69).
- `broadcasts.create(scheduled_at:)` agenda a campanha, que nasce `scheduled` (RB-OPS-70).
- `BroadcastDetail#metrics` (`Models::BroadcastMetrics`) em `broadcasts.get` (RB-OPS-71).
- `Contact#subscribed` (`false` quando o contato se descadastrou; `nil` equivale a inscrito) (RB-OPS-72).
- `SenderDetail#verification_token` fica `nil` em `senders.create`: a API não devolve mais o token, que segue por e-mail ao endereço cadastrado (RB-OPS-73).
- `domains.rotate_dkim(id)` inicia a rotação de DKIM (idempotente) e devolve `Models::DkimRotation` (RB-OPS-74).
- `domains.set_tracking_domain(id, host:)` e `domains.remove_tracking_domain(id)` configuram o domínio de rastreamento e devolvem `Models::CustomHostStatus` (RB-OPS-75, RB-OPS-76).
- `DomainDetail#dkim_rotation`, `#return_path`, `#tracking_domain` e `#tracking_domains_available` em `domains.get` (RB-OPS-77).
- `DomainWarmup#status`, `#total_days`, `#started_at` e `#completed_at` em `domains.get_warmup_status` (RB-OPS-78).
- Enums `CoffeeMail::DomainWarmupStatus` e `CoffeeMail::DnsRecordType` (RB-OPS-79).
- `templates.list_versions(id, limit:, offset:)`, `templates.get_version(id, version)` e `templates.restore_version(id, version)`, com `Models::TemplateVersionList`, `Models::TemplateVersionSummary` e `Models::TemplateVersion` (RB-OPS-80 a RB-OPS-82).
- `template_id` em `emails.send` e `emails.send_batch` aceita o id ou o alias do template (RB-OPS-83).
- `client.validation.validate(emails)` valida de 1 a 100 endereços e devolve `Models::EmailValidationResult` com o saldo de créditos (`Models::ValidationCredits`) (RB-OPS-84).
- O 429 `VALIDATION_CREDITS_EXHAUSTED` vira `RateLimitError` e não é repetido pela `RetryPolicy` (RB-OPS-85).
- `webhooks.get_delivery(id, delivery_id)` e `webhooks.replay_delivery(id, delivery_id)`, com `Models::WebhookDeliveryDetail` (`request_payload`) (RB-OPS-86, RB-OPS-87).

- `CoffeeMail::Client` com as 61 operações da API de produto, no mesmo contrato dos SDKs Node.js, Python, PHP, Java e Go: `emails`, `domains`, `templates`, `audiences` (com `contacts`), `broadcasts`, `senders`, `suppressions`, `webhooks` e `stats`, além da introspecção da chave com cache de 5 minutos.
- Envelope `CoffeeMail::Response` (`data`/`error`, desestruturação, pattern matching e `unwrap!`) e hierarquia de erros com código canônico, `api_code`, `details` e `request_id`.
- Mensagens de erro locais em português (padrão) e inglês.
- `CoffeeMail::Webhook` (`verify`, `construct_event`, `from_rack`), compatível com a assinatura enviada pela API e validado pelos vetores compartilhados.
- `CoffeeMail::RetryPolicy` (opt-in) e `pages` para percorrer listas paginadas.
- `CoffeeMail.with_request_id` para propagar `x-request-id`.
- Assinaturas RBS em `sig/`, verificadas pelo Steep em modo estrito.
- Especificação em `specs/SPEC.md`, com rastreabilidade entre requisitos e testes verificada no CI.

### Corrigido

- `domains.get_warmup_status` com resposta JSON `null` devolve `data == nil` com sucesso, em vez de `InvalidResponseError` (RB-OPS-78).

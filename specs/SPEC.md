# SPEC — SDK Ruby do CoffeeMail (`coffeemail`)

| | |
| --- | --- |
| **Status** | Aprovado em 2026-10-14 |
| **Data** | 2026-10-14 |
| **Gem** | `coffeemail` (livre no RubyGems em 2026-10-14) · `require "coffeemail"` · módulo `CoffeeMail` |
| **Repositório** | `Coffee-Mail/coffee-mail-sdk-ruby` |
| **Versão alvo** | `0.1.0` |
| **Ruby mínimo** | 3.3 (3.2 sem suporte desde 2026-03). CI: 3.3, 3.4 e estável |
| **Contrato** | Spec público `https://api.coffeemail.com.br/v1/product/docs/json`, snapshot em `openapi/product.json` |
| **Norma** | Skill `coffeemail-sdk`; referência de comportamento: SDK Java |

## 1. Método de trabalho (SDD)

- Todo comportamento do SDK nasce como requisito numerado neste arquivo, com critério de aceite verificável.
- O teste é escrito antes do código e o nome começa pelo ID do requisito, por exemplo `it "RB-ERR-07 ..."`. O teste falha antes de existir implementação.
- `bin/check-spec-coverage` faz parte do CI e falha em dois casos: um ID deste arquivo sem nenhum teste, ou um teste que cita um ID inexistente.
- Mudança de comportamento altera este arquivo no mesmo commit e entra no `CHANGELOG.md` em "Não lançado".
- Notação: **[M]** é obrigatório para a 0.1.0. **[S]** é recomendado; se ficar para depois, vira dívida registrada no §11.

## 2. Decisões

| # | Decisão | Motivo |
| --- | --- | --- |
| D1 | Zero dependência de runtime: só `net/http`, `json`, `openssl`, `time`, `securerandom`, `uri` | Princípio 6 da skill |
| D2 | Tipagem com RBS em `sig/` + Steep em modo strict | O equivalente ao mypy strict/phpstan 9, sem dependência de runtime; o RBS também alimenta o gate de compatibilidade |
| D3 | Modelos de resposta com `Data.define` | São imutáveis, nativos desde o Ruby 3.2 e suportam pattern matching |
| D4 | Testes com RSpec, cobertura com SimpleCov | O transporte falso injetado por `transport:` é o ponto de teste |
| D5 | Sem `base_url` | Princípio 3 da skill |
| D6 | `emails.send` e `broadcasts.send` mantêm o nome do contrato | Paridade com os outros SDKs e precedente de outras gems de email. Internamente o SDK só usa `public_send`/`__send__` |
| D7 | Entrada por keyword args, com tabela explícita de chaves snake → camel por operação | Kwarg desconhecido gera `ArgumentError` do próprio Ruby, que é um erro de programação. Nenhum campo fora do contrato chega à API |
| D8 | Retry e paginação automática entram opt-in, desligados por padrão | `transport.md` §4 e §5 |
| D9 | Sem client assíncrono | O client é thread-safe e compatível com Fiber Scheduler via `Net::HTTP`. Não há demanda que justifique outro client |
| D10 | Integração Rails em uma gem separada, `coffeemail-rails` (SPEC próprio) | O SDK fica sem dependência de Rails |

## 3. Client e configuração — `RB-CLI`

| ID | Req. | Critério de aceite |
| --- | --- | --- |
| RB-CLI-01 | [M] | `CoffeeMail::Client.new(api_key: "cm_test_...")` constrói um client. Os kwargs aceitos são `api_key:`, `locale:`, `timeout:`, `retry_policy:` e `transport:` (`retry` é palavra reservada em Ruby). **Não** existe `base_url:`, e passar esse kwarg gera `ArgumentError` |
| RB-CLI-02 | [M] | Sem `api_key:`, o client usa `ENV["COFFEEMAIL_API_KEY"]` |
| RB-CLI-03 | [M] | Sem chave, ou com chave vazia ou só de espaços, levanta `CoffeeMail::MissingApiKeyError` com a mensagem `MISSING_API_KEY` no locale. É o único erro de construção. O formato da chave não é validado |
| RB-CLI-04 | [M] | `locale:` aceita `"pt-BR"` (padrão) e `"en"`. As constantes ficam em `CoffeeMail::Locale::PT_BR` e `CoffeeMail::Locale::EN`. Locale desconhecido gera `ArgumentError` |
| RB-CLI-05 | [M] | `timeout:` em segundos (Numeric > 0), com padrão `10` |
| RB-CLI-06 | [M] | O client e a configuração ficam congelados (`frozen?`) depois de construídos. Uma instância é segura para uso concorrente entre threads |
| RB-CLI-07 | [M] | `inspect` e `to_s` do client não contêm a API key; mostram `cm_****` com no máximo o prefixo |
| RB-CLI-08 | [M] | Os recursos ficam em leitores: `emails`, `domains`, `templates`, `audiences` (com `audiences.contacts`), `broadcasts`, `senders`, `suppressions`, `webhooks` e `stats` |
| RB-CLI-09 | [M] | `CoffeeMail::VERSION` é a única origem da versão |

## 4. Transporte e headers — `RB-TRN`

| ID | Req. | Critério de aceite |
| --- | --- | --- |
| RB-TRN-01 | [M] | A URL base é fixa: `https://api.coffeemail.com.br` + `/v1/product` + rota |
| RB-TRN-02 | [M] | Todo request leva `Authorization: Bearer <key>`, `Accept: application/json`, `Accept-Language: <locale>` e `User-Agent: coffeemail-ruby/<VERSION>` |
| RB-TRN-03 | [M] | `Content-Type: application/json` vai só quando há corpo |
| RB-TRN-04 | [M] | `idempotency_key:` em `emails.send` vira `x-idempotency-key`, e `sandbox: true` vira `x-coffeemail-sandbox: true`. Nenhum dos dois vai no corpo |
| RB-TRN-05 | [M] | Em `emails.send_batch`, o SDK lê a idempotência e o sandbox de cada item, une os headers e retira esses campos dos corpos |
| RB-TRN-06 | [S] | `CoffeeMail.with_request_id(id) { ... }` propaga `x-request-id` em toda requisição feita dentro do bloco (storage de Fiber herdável, o equivalente ao `context` do Go), inclusive em threads e fibers filhas; fora do bloco, o header não é enviado |
| RB-TRN-07 | [M] | O transporte é injetável: qualquer objeto com `call(CoffeeMail::HttpRequest) -> CoffeeMail::HttpResponse`. Os dois tipos são `Data` públicos (`http_method`, `url`, `headers`, `body`, `timeout` / `status`, `headers`, `body`) |
| RB-TRN-08 | [M] | O transporte padrão usa `Net::HTTP` com `use_ssl`, e `open_timeout`, `read_timeout` e `write_timeout` iguais ao `timeout`. Não usa `Timeout.timeout` |
| RB-TRN-09 | [M] | Um timeout vira `NetworkError` com status `0`, code `NETWORK_ERROR` e a mensagem `REQUEST_TIMEOUT` (`{timeoutMs}` preenchido) |
| RB-TRN-10 | [M] | Falhas de socket, DNS, TLS ou conexão recusada viram `NetworkError` com a mensagem `NETWORK_ERROR` (`{details}` preenchido) e a exceção original em `cause` |
| RB-TRN-11 | [M] | Uma resposta 204, ou 2xx com corpo vazio, é sucesso com `data == CoffeeMail::NO_CONTENT` |
| RB-TRN-12 | [M] | Um 2xx com corpo que não é JSON vira `InvalidResponseError` com code `INVALID_RESPONSE` e a mensagem `INVALID_JSON` |
| RB-TRN-13 | [M] | Parâmetros de path são escapados com `URI.encode_www_form_component`. A query omite `nil` e serializa `Time` como ISO-8601 |

## 5. Envelope, erros e i18n — `RB-ERR`

| ID | Req. | Critério de aceite |
| --- | --- | --- |
| RB-ERR-01 | [M] | Toda operação devolve `CoffeeMail::Response`, com `data` **ou** `error` (nunca os dois), `status`, `success?` e `failure?` |
| RB-ERR-02 | [M] | `data, error = response` funciona via `to_ary`, e `response => {data:}` funciona via `deconstruct_keys` |
| RB-ERR-03 | [M] | `unwrap!` devolve `data` no sucesso e levanta o `error` na falha. Nenhuma outra operação levanta exceção por erro de API ou de rede |
| RB-ERR-04 | [M] | `CoffeeMail::Error < StandardError` expõe `status`, `code` (canônico), `api_code`, `message`, `details` (Hash congelado) e `request_id` |
| RB-ERR-05 | [M] | O mapeamento usa a tabela `STATUS_TABLE`: 400 → `ValidationError`/`VALIDATION_ERROR`, 401 → `AuthenticationError`/`UNAUTHORIZED`, 402 → `PaymentRequiredError`/`PAYMENT_REQUIRED`, 403 → `ForbiddenError`/`FORBIDDEN`, 404 → `NotFoundError`/`NOT_FOUND`, 409 → `ConflictError`/`CONFLICT`, 429 → `RateLimitError`/`RATE_LIMIT_EXCEEDED`, e 500, 502, 503 e 504 → `InternalServerError`/`INTERNAL_SERVER_ERROR` |
| RB-ERR-06 | [M] | Outro status não-2xx vira `CoffeeMail::Error` com o code da API ou `API_ERROR` |
| RB-ERR-07 | [M] | A mensagem segue esta ordem: `error.message` → `message` no topo → corpo bruto não JSON e não vazio → catálogo local (`RATE_LIMIT_EXCEEDED` no 429, `UNEXPECTED_ERROR` nos demais, inclusive o 401 sem `message`) |
| RB-ERR-08 | [M] | `api_code` preserva o `error.code` original (por exemplo `PLAN_QUOTA_EXCEEDED`), e `details` é o merge de `error.meta` com `error.details` |
| RB-ERR-09 | [M] | `request_id` vem do header `x-request-id` da resposta |
| RB-ERR-10 | [M] | No 429, `retry_after_seconds` vem de `Retry-After` (Integer). Um valor inválido vira `nil` |
| RB-ERR-11 | [M] | Em toda operação de `broadcasts`, um 403 vira `PermissionError`, com code `PERMISSION_DENIED`, `required_permission == "full_access"`, `details` com `operation` e `requiredPermission`, e a mensagem `PERMISSION_DENIED` com `{requiredPermission}` = `full_access (called by broadcasts.<método>)` |
| RB-ERR-12 | [M] | O catálogo pt-BR/en é literalmente igual ao `Messages.java` do SDK Java (trocando só a referência ao construtor por `CoffeeMail::Client.new`) nas chaves `MISSING_API_KEY`, `REQUEST_TIMEOUT`, `NETWORK_ERROR`, `UNEXPECTED_ERROR`, `INVALID_JSON`, `RATE_LIMIT_EXCEEDED` e `PERMISSION_DENIED`. Uma mensagem vinda do servidor passa intacta |
| RB-ERR-13 | [M] | `inspect` e `to_s` de erro e de request nunca contêm a API key nem o segredo de webhook |

## 6. Operações — `RB-OPS`

Todas as rotas são relativas a `/v1/product`. Path params são posicionais; o resto vai em keyword args snake_case, traduzidos pela tabela da operação (D7). Os campos com `*` são obrigatórios na API: viram kwargs obrigatórios do método, e os outros são opcionais (`nil` é omitido). `GET /auth/csrf` fica fora (é exclusiva de navegador).

| ID | Método Ruby | HTTP | Corpo / query |
| --- | --- | --- | --- |
| RB-OPS-01 | `emails.send(**)` | POST `/emails` → 202 | from\*, to\*, cc, bcc, reply_to, subject, html, text, headers, attachments, template_id, variables, email_type, suppression_category, tags, scheduled_at, metadata + idempotency_key, sandbox |
| RB-OPS-02 | `emails.send_batch(items)` | POST `/emails/batch` → 202 | Array de 1–100 hashes no formato do RB-OPS-01. Resposta: um item por entrada, sucesso ou erro |
| RB-OPS-03 | `emails.get(id)` | GET `/emails/{id}` | — |
| RB-OPS-04 | `emails.list(**)` | GET `/emails` (cursor) | status, recipient, from_email, subject_contains, api_key_id, tag, from, to, after, limit |
| RB-OPS-05 | `emails.get_events(id)` | GET `/emails/{id}/events` | — |
| RB-OPS-06 | `emails.get_tags` | GET `/emails/tags` | — |
| RB-OPS-07 | `emails.cancel(id)` | POST `/emails/{id}/cancel` → 204 | — |
| RB-OPS-08 | `emails.resend(id)` | POST `/emails/{id}/resend` → 202 | — |
| RB-OPS-09 | `domains.create(name:)` | POST `/domains` | name\* |
| RB-OPS-10 | `domains.list` | GET `/domains` | — |
| RB-OPS-11 | `domains.get(id)` | GET `/domains/{id}` | — |
| RB-OPS-12 | `domains.verify(id)` | POST `/domains/{id}/verify` | — |
| RB-OPS-13 | `domains.delete(id)` | DELETE `/domains/{id}` | sem corpo (a reautenticação é só do dashboard; exceção explícita na conformidade) |
| RB-OPS-14 | `domains.get_health(id)` | POST `/domains/{id}/health` | — |
| RB-OPS-15 | `domains.get_warmup_status(id)` | GET `/domains/{id}/warmup` | um corpo vazio vira `data == nil` com sucesso |
| RB-OPS-16 | `templates.create(**)` | POST `/templates` | name\*, html\*, alias, subject, preheader, content_json, text_payload, variables, format, source_locale |
| RB-OPS-17 | `templates.list` | GET `/templates` | resposta `{data: [...]}` → Array |
| RB-OPS-18 | `templates.get(id)` | GET `/templates/{id}` | — |
| RB-OPS-19 | `templates.update(id, **)` | PATCH `/templates/{id}` | os campos do create, todos opcionais, + is_active |
| RB-OPS-20 | `templates.delete(id)` | DELETE `/templates/{id}` → 204 | — |
| RB-OPS-21 | `templates.preview(**)` | POST `/templates/preview` | html\*, format, variables |
| RB-OPS-22 | `templates.preview_by_id(id, variables: nil)` | composta: `get` + `preview` | usa o `html` e o `format` do template; se o `get` falhar, devolve essa falha |
| RB-OPS-23 | `templates.format(**)` | POST `/templates/format` | html\*, format |
| RB-OPS-24 | `templates.test_render(**)` | POST `/templates/test-render` | html\*, format, variables |
| RB-OPS-25 | `templates.test_send(id, **)` | POST `/templates/{id}/test-send` | to\*, from, subject, variables |
| RB-OPS-26 | `audiences.create(**)` | POST `/audiences` | name\*, description |
| RB-OPS-27 | `audiences.list(**)` | GET `/audiences` (offset) | limit, offset |
| RB-OPS-28 | `audiences.get(id)` | GET `/audiences/{id}` | — |
| RB-OPS-29 | `audiences.update(id, **)` | PUT `/audiences/{id}` | name, description, active |
| RB-OPS-30 | `audiences.delete(id)` | DELETE `/audiences/{id}` | — |
| RB-OPS-31 | `audiences.contacts.create(audience_id, **)` | POST `/audiences/{id}/contacts` | email\*, first_name, last_name, metadata |
| RB-OPS-32 | `audiences.contacts.list(audience_id, **)` | GET `/audiences/{id}/contacts` (offset) | limit, offset; resposta com `contacts` e `total` |
| RB-OPS-33 | `audiences.contacts.bulk_add(audience_id, contacts:)` | POST `/audiences/{id}/contacts/bulk` | contacts\* (≤ 10 000) |
| RB-OPS-34 | `audiences.contacts.update(audience_id, contact_id, **)` | PUT `/audiences/{id}/contacts/{contactId}` | first_name, last_name, metadata |
| RB-OPS-35 | `audiences.contacts.delete(audience_id, contact_id)` | DELETE `/audiences/{id}/contacts/{contactId}` | — |
| RB-OPS-36 | `broadcasts.create(**)` | POST `/broadcasts` | audience_id\*, from_email\*, template_id, subject, html, text, reply_to, variables |
| RB-OPS-37 | `broadcasts.list(**)` | GET `/broadcasts` (cursor) | status, from, to, after, limit |
| RB-OPS-38 | `broadcasts.get(id)` | GET `/broadcasts/{id}` | — |
| RB-OPS-39 | `broadcasts.send(id)` | POST `/broadcasts/{id}/send` | — |
| RB-OPS-40 | `broadcasts.test_send(id, **)` | POST `/broadcasts/{id}/test-send` | to\*, variables |
| RB-OPS-41 | `broadcasts.cancel(id)` | POST `/broadcasts/{id}/cancel` | — (não existe `delete`) |
| RB-OPS-42 | `senders.create(**)` | POST `/senders` | email\*, display_name |
| RB-OPS-43 | `senders.list` | GET `/senders` | — |
| RB-OPS-44 | `senders.verify(token:)` | POST `/senders/verify` | token\* |
| RB-OPS-45 | `senders.delete(id)` | DELETE `/senders/{id}` | — |
| RB-OPS-46 | `suppressions.create(**)` | POST `/suppressions` | email\*, reason, expires_at |
| RB-OPS-47 | `suppressions.list(**)` | GET `/suppressions` (cursor) | status, reason, source, category, after, limit |
| RB-OPS-48 | `suppressions.get(id)` | GET `/suppressions/{id}` | é o **id**, nunca o email |
| RB-OPS-49 | `suppressions.delete(id)` | DELETE `/suppressions/{id}` | — |
| RB-OPS-50 | `suppressions.reactivate(id)` | POST `/suppressions/{id}/reactivate` | — |
| RB-OPS-51 | `suppressions.bulk_create(suppressions:)` | POST `/suppressions/bulk` | suppressions\* (≤ 1000) |
| RB-OPS-52 | `webhooks.create(**)` | POST `/webhooks` | url\*, events\*, description; o `secret` vem na resposta uma única vez |
| RB-OPS-53 | `webhooks.list(**)` | GET `/webhooks` | status |
| RB-OPS-54 | `webhooks.get(id)` | GET `/webhooks/{id}` | — |
| RB-OPS-55 | `webhooks.update(id, **)` | PUT `/webhooks/{id}` | url, events, description (parcial) |
| RB-OPS-56 | `webhooks.toggle(id, status:)` | PATCH `/webhooks/{id}` | status\* (`active` \| `paused`) |
| RB-OPS-57 | `webhooks.delete(id)` | DELETE `/webhooks/{id}` | — |
| RB-OPS-58 | `webhooks.rotate_secret(id)` | POST `/webhooks/{id}/rotate-secret` | — |
| RB-OPS-59 | `webhooks.list_deliveries(id, **)` | GET `/webhooks/{id}/deliveries` | event_type, status, from, to, limit |
| RB-OPS-60 | `webhooks.test(id)` | POST `/webhooks/{id}/test` | — |
| RB-OPS-61 | `stats.get(**)` | GET `/stats` | domain_id, tag, start_date, end_date, granularity, period, email_type |
| RB-OPS-62 | `client.introspect(force_refresh: false)` | GET `/auth/me/api-key` | `{id, name, organisation_id, scopes}`. O cache dura 5 min, protegido por `Mutex`. `client.invalidate_api_key_cache` limpa o cache |

`preview_by_id` é composta e não conta como rota: são 71 rotas mais 1 composta (RB-OPS-69 acrescentou a 62ª; RB-OPS-74 a RB-OPS-76, as três de entregabilidade; RB-OPS-80 a RB-OPS-82, RB-OPS-84, RB-OPS-86 e RB-OPS-87, as seis da onda 4).

Requisitos transversais das operações:

| ID | Req. | Critério de aceite |
| --- | --- | --- |
| RB-OPS-63 | [M] | Teste de conformidade: todo `MÉTODO + path` de `openapi/product.json` (exceto `/auth/csrf`) está mapeado para um método, e todo método mapeia para uma rota existente |
| RB-OPS-64 | [M] | O corpo e a query de cada operação são validados contra o schema do snapshot, com `additionalProperties` incluído |
| RB-OPS-65 | [M] | As respostas viram modelos `Data` imutáveis. Datas viram `Time`, campo desconhecido é ignorado e campo ausente vira `nil` |
| RB-OPS-66 | [M] | Enums são abertos: constantes String (`CoffeeMail::EmailStatus::DELIVERED`) e um valor desconhecido passa sem erro |
| RB-OPS-67 | [M] | As respostas não documentadas no spec (`GET /audiences`, `GET` e `send` de broadcasts, `rotate-secret` e `/auth/me/api-key`) são modeladas pelo SDK Java e cobertas por teste |
| RB-OPS-68 | [M] | O `list` com cursor expõe `next_cursor` (nil no fim). O `list` com offset expõe os itens e, em contacts, `total` |
| RB-OPS-69 | [M] | `senders.resend_verification(id)` → POST `/senders/{id}/resend-verification` → 204: reenvia o e-mail de verificação com token novo; 409 vira `ConflictError` e 404 vira `NotFoundError` |
| RB-OPS-70 | [M] | `broadcasts.create(scheduled_at:)` aceita `Time` ou String ISO 8601 e envia `scheduledAt`; a campanha nasce `scheduled` |
| RB-OPS-71 | [M] | `BroadcastDetail#metrics` (`Models::BroadcastMetrics`: delivered, opened, clicked, bounced, failed, suppressed) vem preenchido em `broadcasts.get`; ausente vira `nil` |
| RB-OPS-72 | [M] | `Contact#subscribed` é `false` quando o contato se descadastrou; ausente vira `nil`, que equivale a inscrito |
| RB-OPS-73 | [S] | `SenderDetail#verification_token` fica `nil` em `senders.create`: a API não devolve mais o token, que segue por e-mail ao endereço cadastrado; o campo continua no modelo (depreciado) |
| RB-OPS-74 | [M] | `domains.rotate_dkim(id)` → POST `/domains/{id}/dkim/rotate`, sem corpo → `Models::DkimRotation` (`domain_id`, `selector`, `started_at` como `Time`, `record` como `Models::DnsRecord`). É idempotente: chamar de novo com uma rotação pendente devolve a mesma rotação. 404 (`DOMAIN_NOT_FOUND`) vira `NotFoundError` e 409 (`DOMAIN_NOT_VERIFIED`) vira `ConflictError`, com o código da API em `api_code` |
| RB-OPS-75 | [M] | `domains.set_tracking_domain(id, host:)` → PUT `/domains/{id}/tracking-domain` com `{host}` → `Models::CustomHostStatus` (`host`, `target`, `verified`, `verified_at` como `Time` ou `nil`, `record`). 400 (`INVALID_TRACKING_HOST`) vira `ValidationError`, 409 (`TRACKING_DOMAINS_DISABLED`) vira `ConflictError` e 404 vira `NotFoundError` |
| RB-OPS-76 | [M] | `domains.remove_tracking_domain(id)` → DELETE `/domains/{id}/tracking-domain`, sem corpo → `Models::CustomHostStatus` ou `nil` (corpo vazio ou JSON `null`, ambos com sucesso) |
| RB-OPS-77 | [M] | `DomainDetail` (`domains.get`) expõe `dkim_rotation` (`DkimRotation`), `return_path` e `tracking_domain` (`CustomHostStatus`) e `tracking_domains_available` (Boolean); `null` ou ausente vira `nil`. Os membros novos vêm depois dos existentes |
| RB-OPS-78 | [M] | `DomainWarmup` (`domains.get_warmup_status`) expõe `status` (`warming` \| `completed`), `total_days`, `started_at` (`Time`) e `completed_at` (`Time` ou `nil`). Uma resposta JSON `null` vira `data == nil` com sucesso, como o corpo vazio do RB-OPS-15 |
| RB-OPS-79 | [S] | Enums abertos novos: `CoffeeMail::DomainWarmupStatus` (`WARMING`, `COMPLETED`) e `CoffeeMail::DnsRecordType` (`TXT`, `CNAME`) |
| RB-OPS-80 | [M] | `templates.list_versions(id, limit: nil, offset: nil)` → GET `/templates/{id}/versions` (offset; `limit` de 1 a 100) → `Models::TemplateVersionList` (`data`: Array de `Models::TemplateVersionSummary` com `version`, `name`, `subject` ou `nil`, `created_by` ou `nil` quando a versão veio de API key, `created_at` como `Time`; `total`). Sem filtros, não envia query. 404 (`TEMPLATE_NOT_FOUND`) vira `NotFoundError` |
| RB-OPS-81 | [M] | `templates.get_version(id, version)` → GET `/templates/{id}/versions/{version}` → `Models::TemplateVersion` (os campos do resumo + `template_id`, `preheader`, `html`, `content_json`, `text_payload`, `variables`, `format`, `source_locale`). 404 `TEMPLATE_NOT_FOUND` e `TEMPLATE_VERSION_NOT_FOUND` viram `NotFoundError`, com o código em `api_code` |
| RB-OPS-82 | [M] | `templates.restore_version(id, version)` → POST `/templates/{id}/versions/{version}/restore`, sem corpo → `Models::TemplateDetail`. 404 `TEMPLATE_NOT_FOUND` e `TEMPLATE_VERSION_NOT_FOUND` viram `NotFoundError` |
| RB-OPS-83 | [M] | `template_id` em `emails.send` e `emails.send_batch` aceita o id ou o alias do template e vai como veio, sem validação local de formato (a API exige `^[a-z0-9_-]+$`) |
| RB-OPS-84 | [M] | `client.validation.validate(emails)` → POST `/validate` com `{emails}` (1 a 100 Strings) → `Models::EmailValidationResult` (`items`: Array de `Models::EmailValidationItem` com `email`, `format_valid`, `mx_valid`, `is_disposable` e `reason` ou `nil`; `valid_count`; `invalid_count`; `credits`: `Models::ValidationCredits` com `limit` e `remaining` `nil` quando ilimitado, e `used`). 400 vira `ValidationError` |
| RB-OPS-85 | [M] | O 429 `VALIDATION_CREDITS_EXHAUSTED` (créditos de validação do mês esgotados) vira `RateLimitError` com o código em `api_code` e nunca é retentado automaticamente, nem com `RetryPolicy` ligada nem em requisição elegível a retry |
| RB-OPS-86 | [M] | `webhooks.get_delivery(id, delivery_id)` → GET `/webhooks/{id}/deliveries/{deliveryId}` → `Models::WebhookDeliveryDetail` (os campos de `WebhookDelivery` + `request_payload`, o corpo enviado). 404 `WEBHOOK_NOT_FOUND` e `WEBHOOK_DELIVERY_NOT_FOUND` viram `NotFoundError` |
| RB-OPS-87 | [M] | `webhooks.replay_delivery(id, delivery_id)` → POST `/webhooks/{id}/deliveries/{deliveryId}/replay`, sem corpo → 202 com a entrega nova (`Models::WebhookDeliveryDetail`). 409 `WEBHOOK_DELIVERY_PENDING` e `WEBHOOK_NOT_ACTIVE` viram `ConflictError`; 404 `WEBHOOK_NOT_FOUND` e `WEBHOOK_DELIVERY_NOT_FOUND` viram `NotFoundError` |

## 7. Webhooks — `RB-WHK`

| ID | Req. | Critério de aceite |
| --- | --- | --- |
| RB-WHK-01 | [M] | `CoffeeMail::Webhook.verify(payload:, headers:, secret:, tolerance: 300, clock: nil) -> bool` não depende do client nem de API key |
| RB-WHK-02 | [M] | A assinatura esperada é `"sha256=" + hex_lower(HMAC-SHA256(secret, "#{ts}.#{idem}.#{raw_body}"))`. O segredo `whsec_...` é usado inteiro como bytes UTF-8, e o corpo é usado em bytes exatos, nunca re-serializado |
| RB-WHK-03 | [M] | A comparação roda em tempo constante (`OpenSSL.fixed_length_secure_compare` após checar o tamanho). Hex maiúsculo é rejeitado |
| RB-WHK-04 | [M] | `\|now - ts\| <= tolerance` com relógio injetável. Timestamp não numérico, ausente, expirado ou no futuro além da tolerância dá `false` |
| RB-WHK-05 | [M] | Os headers são lidos sem diferenciar maiúsculas (`x-webhook-signature`, `x-webhook-timestamp`, `x-webhook-idempotency-key`), tanto em Hash quanto no formato Rack `HTTP_X_WEBHOOK_*` |
| RB-WHK-06 | [M] | `Webhook.construct_event(...)` devolve um `Response` com `CoffeeMail::Webhook::Event` (`event_type`, `webhook_id`, `data`, `test?`) ou `WebhookVerificationError` com o motivo (`:signature`, `:timestamp`, `:missing_header`, `:payload`) |
| RB-WHK-07 | [S] | `Webhook.from_rack(request_or_env, secret:, tolerance: 300)` lê o corpo bruto (e o rebobina) e delega para o `construct_event`, sem depender da gem `rack` |
| RB-WHK-08 | [M] | Os 11 vetores de `spec/fixtures/webhook_vectors.json`, copiados do SDK Java, passam todos |
| RB-WHK-09 | [M] | Os tipos de evento ficam em `CoffeeMail::Webhook::EventType`, com os 16 valores de `webhooks.md` §3 |

## 8. DX opt-in — `RB-DX`

| ID | Req. | Critério de aceite |
| --- | --- | --- |
| RB-DX-01 | [M] | Sem `retry:`, o SDK faz uma única tentativa |
| RB-DX-02 | [M] | `CoffeeMail::RetryPolicy.new(max_attempts:, base_delay: 0.5, max_delay: 30)` liga o retry quando `max_attempts > 1` |
| RB-DX-03 | [M] | O retry só acontece em `NetworkError`, 5xx e 429 com `api_code` diferente de `PLAN_QUOTA_EXCEEDED` e de `VALIDATION_CREDITS_EXHAUSTED` (RB-OPS-85) |
| RB-DX-04 | [M] | Só GET e DELETE são retentados, ou POST com `x-idempotency-key`. Sem chave, o SDK gera `SecureRandom.uuid` antes da 1ª tentativa e reutiliza em todas |
| RB-DX-05 | [M] | O backoff é exponencial com jitter completo, limitado a `max_delay`. `Retry-After` é honrado, também limitado a `max_delay`. O sleep e o aleatório são injetáveis para teste |
| RB-DX-06 | [M] | O PATCH e o PUT não são retentados |
| RB-DX-07 | [S] | `pages(**query)` nos `list` com cursor (emails, broadcasts, suppressions) e com offset (audiences, contacts) devolve um `Enumerator::Lazy` de `Response`, um por página. Para depois da última página ou da primeira falha, que é entregue |

## 9. Qualidade — `RB-QA`

| ID | Req. | Critério de aceite |
| --- | --- | --- |
| RB-QA-01 | [M] | O RuboCop (+ `rubocop-performance`, `rubocop-rspec`) passa sem `rubocop:disable` inline. Exceções ficam no `.rubocop.yml` com justificativa |
| RB-QA-02 | [M] | O cop `CoffeeMail/NoComments` só permite o magic comment `frozen_string_literal` e YARD imediatamente acima de classe, módulo, constante ou método público em `lib/` |
| RB-QA-03 | [M] | Os cops `CoffeeMail/NoElse` (`else`, `elsif`, `unless…else`) e `CoffeeMail/NoCase` (`case/when`, `case/in`) estão ativos. O ternário é permitido |
| RB-QA-04 | [M] | `CoffeeMail/MaxDepth` limita a profundidade a 3, contando condicionais, laços e blocos |
| RB-QA-05 | [M] | `CoffeeMail/RescueOnlyInAdapters` só permite `rescue` e `raise` em `internal/transport_guard.rb` (isola qualquer transporte, inclusive o injetado), `internal/wire.rb` (JSON), `internal/options.rb` (`MissingApiKeyError` e `ArgumentError` de opções), `response.rb` (`unwrap!`) e `retry_policy.rb` (validação) |
| RB-QA-06 | [M] | `CoffeeMail/NoConsole` proíbe `puts`, `print`, `p`, `pp`, `warn`, `$stdout` e `$stderr` em `lib/` |
| RB-QA-07 | [M] | Rotas, headers e defaults ficam em `internal/constants/*` como constantes congeladas. Nomes de campo do contrato ficam nas tabelas de operação |
| RB-QA-08 | [M] | Cada cop próprio tem teste com caso positivo e negativo |
| RB-QA-09 | [M] | `steep check` em modo strict e `rbs validate` passam, e toda a API pública tem assinatura em `sig/` |
| RB-QA-10 | [M] | SimpleCov com ≥ 85% de linhas e ≥ 78% de branches, com falha abaixo disso |
| RB-QA-11 | [M] | `bin/sync-spec [--check]` sincroniza ou verifica o `openapi/product.json` a partir de `COFFEEMAIL_OPENAPI_SPEC`, com o spec público como padrão |
| RB-QA-12 | [M] | `bin/check-spec-coverage` garante a rastreabilidade SDD (§1) |
| RB-QA-13 | [M] | `bin/check-api-compat` compara o RBS público de HEAD com o da última tag: falha se uma classe, método ou kwarg for removido, ou se um kwarg virar obrigatório. Sem tag, passa e reporta "baseline" |
| RB-QA-14 | [M] | `bundle exec bundler-audit check --update` passa |
| RB-QA-15 | [M] | O CI roda nas versões 3.3, 3.4 e estável, na ordem: versão → regras da casa → lint → tipos → testes/cobertura → compat → `gem build` → audit |
| RB-QA-16 | [M] | Nenhum arquivo do repo cita repositório privado. Um grep no CI garante isso |

## 10. Release e documentação — `RB-RLS`

| ID | Req. | Critério de aceite |
| --- | --- | --- |
| RB-RLS-01 | [M] | `bin/check-version-sync`: `CoffeeMail::VERSION` = versão do gemspec = sufixo do `User-Agent` = topo do CHANGELOG (e = tag, no release) |
| RB-RLS-02 | [M] | O gemspec declara `required_ruby_version >= 3.3`, zero `add_dependency`, `files` restritos a `lib/`, `sig/`, `README`, `LICENSE` e `CHANGELOG`, e `metadata` com `rubygems_mfa_required`, `source_code_uri` e `changelog_uri` |
| RB-RLS-03 | [M] | O smoke test instala o `.gem` gerado em um diretório limpo e faz `require "coffeemail"` mais um envio com transporte falso |
| RB-RLS-04 | [M] | O README segue o roteiro único de `quality-gates.md` §6 e documenta a dedup implícita sem chave de idempotência, o webhook sem id do email e a `x-webhook-idempotency-key` que muda a cada tentativa |
| RB-RLS-05 | [M] | Toda a API pública tem YARD. `yard stats --list-undoc` mostra 0 itens sem documentação |
| RB-RLS-06 | [M] | `examples/` tem exemplos executáveis (envio, erros, webhook com Rack), cobertos por teste com transporte falso |
| RB-RLS-07 | [M] | Arquivos de comunidade: `LICENSE`, `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`, `CHANGELOG.md` (Keep a Changelog, pt-BR), `AGENTS.md` e templates de issue/PR |
| RB-RLS-08 | [M] | O `release.yml` é disparado por uma tag `vX.Y.Z`: valida a versão, roda o CI completo e publica no RubyGems por trusted publishing (OIDC), com a GitHub Release levando as notas do CHANGELOG. **A tag só é criada com autorização** |

## 11. Fora do escopo da 0.1.0 e dívidas

- O locale `es` é dívida de todos os SDKs (`errors.md` §4) e entra em todos ao mesmo tempo.
- A integração Rails tem SPEC próprio em `coffee-mail-rails/specs/SPEC.md` (prefixo `RB-RAILS`).
- Não haverá client assíncrono (D9).

## 12. Matriz de rastreabilidade

É gerada pelo `bin/check-spec-coverage --report`, com uma linha por ID e os arquivos de teste que o citam. Não é mantida à mão.

## 13. Aprovação

- [x] SPEC aprovado em 2026-10-14 (libera a Fase 1, scaffold)

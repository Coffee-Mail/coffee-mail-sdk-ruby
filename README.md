<div align="center">

# ☕ CoffeeMail Ruby SDK

**SDK oficial da CoffeeMail para Ruby 3.3+: envio transacional, domínios, templates, audiências, campanhas, supressões, webhooks e estatísticas, sem dependências além da biblioteca padrão.**

[![Gem](https://img.shields.io/gem/v/coffeemail)](https://rubygems.org/gems/coffeemail)
[![CI](https://github.com/Coffee-Mail/coffee-mail-sdk-ruby/actions/workflows/ci.yml/badge.svg)](https://github.com/Coffee-Mail/coffee-mail-sdk-ruby/actions/workflows/ci.yml)
[![Ruby](https://img.shields.io/badge/ruby-3.3%2B-CC342D)](#-requisitos)
[![Licença: MIT](https://img.shields.io/badge/licen%C3%A7a-MIT-blue.svg)](LICENSE)

[Instalação](#-instalação) · [Início rápido](#-início-rápido) · [Erros](#️-tratamento-de-erros) · [Referência](#-referência) · [Webhooks](#-webhooks) · [Versionamento](#-versionamento-e-releases)

</div>

---

## 📑 Sumário

- [Visão geral](#-visão-geral)
- [Status do projeto](#-status-do-projeto)
- [Requisitos](#-requisitos)
- [Instalação](#-instalação)
- [Início rápido](#-início-rápido)
- [Configuração](#️-configuração)
- [Tratamento de erros](#️-tratamento-de-erros)
- [Novas tentativas](#-novas-tentativas)
- [Paginação](#-paginação)
- [Referência](#-referência)
- [Webhooks](#-webhooks)
- [Versionamento e releases](#-versionamento-e-releases)
- [Testes e qualidade](#-testes-e-qualidade)
- [Estrutura do repositório](#️-estrutura-do-repositório)
- [Contribuição](#-contribuição)
- [Projetos relacionados](#-projetos-relacionados)
- [Licença](#-licença)

## ✨ Visão geral

- **Mesmo contrato dos SDKs oficiais** (Node.js, Python, PHP, Java, Go): mesmos recursos, mesmos métodos, mesmos códigos de erro e mesmas mensagens locais.
- **Idiomático**: keyword args em snake_case, modelos imutáveis (`Data`), datas como `Time`, enums como constantes `String`.
- **Sem exceções por padrão**: toda operação devolve um `CoffeeMail::Response` com `data` **ou** `error`. Desestruture com `data, error = ...`, use pattern matching ou chame `unwrap!` quando preferir exceção.
- **Zero dependências de runtime**: só `net/http`, `json` e `openssl`. O transporte é injetável.
- **Seguro entre threads**: crie um `Client` por aplicação e compartilhe.
- **Retry e paginação automáticos opcionais**: novas tentativas desligadas por padrão (`RetryPolicy`) e `pages` preguiçoso para listas paginadas.
- **Tipado**: assinaturas RBS em `sig/`, verificadas pelo Steep em modo estrito.
- **Validado contra o contrato da API**: as 64 operações geram requisições validadas contra o OpenAPI de produto (`openapi/product.json`).
- **Webhooks verificados com o algoritmo da API**: `CoffeeMail::Webhook` passa nos vetores de teste gerados pelo assinador real.

## 🚦 Status do projeto

| Item | Estado |
| --- | --- |
| Versão | `0.1.0` (ainda não publicada) |
| Cobertura da API de produto | 64 operações (todas as do `product.json`, exceto `GET /v1/product/auth/csrf`, exclusiva do dashboard) |
| Idiomas das mensagens de erro | `pt-BR` (padrão) e `en` |
| Especificação | [`specs/SPEC.md`](specs/SPEC.md), com cada requisito coberto por teste |

Limitações conhecidas:

- **Pré-1.0**: a série `0.x` segue semver, mas a política da casa já proíbe quebrar a superfície pública.
- **`templates.preview_by_id`** não é um endpoint próprio: faz `GET /templates/{id}` e depois `POST /templates/preview` com o HTML do template (duas requisições).
- **Campos que podem ser limpos** (`description`, `alias`...): nos métodos de atualização, `nil` significa "não alterar". Enviar `null` explícito para limpar um campo ainda não é suportado.
- **Lacuna do `product.json`**: `DELETE /domains/{id}` declara no spec um corpo de reautenticação obrigatório, que a API só exige em sessões do dashboard. O teste de contrato trata essa rota como exceção explícita.

## 📋 Requisitos

- Ruby 3.3 ou superior.
- Uma chave de API (`cm_live_...` ou `cm_test_...`), criada no dashboard da CoffeeMail.

## 📦 Instalação

```bash
bundle add coffeemail
```

Ou, no `Gemfile`:

```ruby
gem "coffeemail", "~> 0.1"
```

## 🚀 Início rápido

```ruby
require "coffeemail"

client = CoffeeMail::Client.new(api_key: ENV.fetch("COFFEEMAIL_API_KEY"))

data, error = client.emails.send(
  from: { email: "app@exemplo.com.br", name: "Minha App" },
  to: "ana@exemplo.com.br",
  subject: "Bem-vinda!",
  html: "<p>Olá, Ana!</p>",
)

if error
  warn "#{error.code}: #{error.message}"
else
  puts "E-mail #{data.id} #{data.status}"
end
```

Endereços aceitam `String` (`"ana@exemplo.com.br"`) ou `Hash` (`{ email:, name: }`), e `to`, `cc` e `bcc` aceitam um endereço ou uma lista.

> **Deduplicação implícita:** sem `idempotency_key`, a API deduplica envios idênticos pelo hash do payload, e dois `send` iguais devolvem o mesmo id. Para enviar de novo o mesmo conteúdo, ou para controlar a deduplicação explicitamente, informe `idempotency_key:`. Com uma chave repetida, a API devolve o id original (janela de 24 h).

`sandbox: true` envia o header `x-coffeemail-sandbox` e simula o envio. `idempotency_key` e `sandbox` viram headers e nunca vão no corpo.

## ⚙️ Configuração

```ruby
client = CoffeeMail::Client.new(
  api_key: "cm_live_...",                   # sem ela, usa COFFEEMAIL_API_KEY
  locale: CoffeeMail::Locale::EN,           # "pt-BR" (padrão) ou "en"; vai também em Accept-Language
  timeout: 5,                               # segundos por tentativa (padrão 10)
  retry_policy: CoffeeMail::RetryPolicy.new(max_attempts: 3),
  transport: meu_transporte,                # qualquer objeto com call(HttpRequest) -> HttpResponse
)
```

- Sem chave de API, `Client.new` levanta `CoffeeMail::MissingApiKeyError`. É o único erro de construção. Opções inválidas levantam `ArgumentError`.
- **Não existe opção de URL base.** O SDK fala só com `https://api.coffeemail.com.br`, para que a sua chave nunca seja enviada a outro host. Para testes, proxy ou instrumentação, injete um `transport:`.
- `inspect` e `to_s` do client, das requisições e dos erros nunca mostram a chave.
- `CoffeeMail.with_request_id(id) { ... }` propaga `x-request-id` em toda requisição feita dentro do bloco, inclusive em threads filhas.

## 🛡️ Tratamento de erros

```ruby
response = client.emails.get(id)

response.success?            # true/false
data, error = response       # desestruturação
response => { data: }        # pattern matching
response.unwrap!             # devolve data ou levanta o erro
```

Todo erro herda de `CoffeeMail::Error` (um `StandardError`) e traz `status`, `code` (canônico), `api_code` (o código original da API), `message`, `details` e `request_id`:

| Status | `code` | Classe |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR` | `ValidationError` |
| 401 | `UNAUTHORIZED` | `AuthenticationError` |
| 402 | `PAYMENT_REQUIRED` | `PaymentRequiredError` |
| 403 | `FORBIDDEN` | `ForbiddenError` |
| 403 em broadcasts | `PERMISSION_DENIED` | `PermissionError` (`required_permission`) |
| 404 | `NOT_FOUND` | `NotFoundError` |
| 409 | `CONFLICT` | `ConflictError` |
| 429 | `RATE_LIMIT_EXCEEDED` | `RateLimitError` (`retry_after_seconds`) |
| 500, 502, 503, 504 | `INTERNAL_SERVER_ERROR` | `InternalServerError` |
| rede ou timeout | `NETWORK_ERROR` (status 0) | `NetworkError` (`cause`) |
| 2xx ilegível | `INVALID_RESPONSE` | `InvalidResponseError` |

Um 429 pode ser excesso de requisições ou cota do plano esgotada. Diferencie pelo `api_code` (`PLAN_QUOTA_EXCEEDED`). Quando a API não manda mensagem (o 401, por exemplo), o SDK usa o catálogo local no `locale` do client. Veja [`examples/error_handling.rb`](examples/error_handling.rb).

## 🔁 Novas tentativas

Desligadas por padrão. Com `RetryPolicy.new(max_attempts: 3, base_delay: 0.5, max_delay: 30)`:

- O SDK só repete erros de rede, respostas 5xx e 429 que não sejam `PLAN_QUOTA_EXCEEDED`.
- GET e DELETE são sempre elegíveis. POST só em `emails.send` e `emails.send_batch`: sem `idempotency_key`, o SDK gera um UUID antes da primeira tentativa e o reutiliza em todas. PUT e PATCH nunca são repetidos.
- O backoff é exponencial com jitter completo, limitado a `max_delay`. `Retry-After` é honrado com o mesmo teto (a API responde `60`).

## 📄 Paginação

`list` devolve **uma página**. `pages` percorre todas, de forma preguiçosa, com um `Response` por página, e para na primeira falha:

```ruby
client.emails.pages(status: CoffeeMail::EmailStatus::BOUNCED, limit: 100).each do |page|
  break warn(page.error.message) if page.failure?

  page.data.emails.each { |email| puts email.id }
end
```

| Estilo | Recursos | `pages` |
| --- | --- | --- |
| cursor (`after`, `next_cursor`) | `emails`, `broadcasts`, `suppressions` | `pages(**filtros)` |
| offset (`limit`, `offset`, `total`) | `audiences`, `audiences.contacts` | `pages(limit:, offset: 0)` |

## 📚 Referência

Todos os métodos devolvem `CoffeeMail::Response`. Path params são posicionais, e o resto vai em keyword args.

### Introspecção da chave de API

| Método | Rota |
| --- | --- |
| `client.introspect(force_refresh: false)` | `GET /auth/me/api-key` (cache local de 5 min) |
| `client.invalidate_api_key_cache` | limpa o cache |

### E-mails — `client.emails`

| Método | Rota |
| --- | --- |
| `send(from:, to:, subject:, html:, text:, cc:, bcc:, reply_to:, headers:, attachments:, template_id:, variables:, email_type:, suppression_category:, tags:, scheduled_at:, metadata:, idempotency_key:, sandbox:)` | `POST /emails` |
| `send_batch(items)` (1–100 hashes no formato de `send`) | `POST /emails/batch` |
| `get(id)` · `get_events(id)` · `get_tags` | `GET /emails/{id}` · `/emails/{id}/events` · `/emails/tags` |
| `list(**filtros)` · `pages(**filtros)` | `GET /emails` |
| `cancel(id)` · `resend(id)` | `POST /emails/{id}/cancel` · `/emails/{id}/resend` |

### Domínios — `client.domains`

`create(name:)` · `list` · `get(id)` · `verify(id)` · `delete(id)` · `get_health(id)` · `get_warmup_status(id)` (`data` é `nil` fora do aquecimento) · `rotate_dkim(id)` · `set_tracking_domain(id, host:)` · `remove_tracking_domain(id)` (`data` é `nil` quando não havia domínio de rastreamento).

`get(id)` traz `dkim_rotation` (rotação de DKIM pendente), `return_path` e `tracking_domain` (host próprio com o CNAME a publicar e o status da verificação) e `tracking_domains_available`. O aquecimento expõe `status` (`CoffeeMail::DomainWarmupStatus`), `total_days`, `started_at` e `completed_at`.

```ruby
rotation = client.domains.rotate_dkim(domain_id).unwrap!
rotation.record.host  # publique este TXT; a chave só muda quando ele for encontrado no DNS

tracking, error = client.domains.set_tracking_domain(domain_id, host: "links.exemplo.com.br")
tracking.record.value unless error  # alvo do CNAME
```

`rotate_dkim` é idempotente e devolve `ConflictError` (`api_code == "DOMAIN_NOT_VERIFIED"`) para domínio não verificado. `set_tracking_domain` devolve `ValidationError` (`INVALID_TRACKING_HOST`) para host inválido e `ConflictError` (`TRACKING_DOMAINS_DISABLED`) quando o recurso não está disponível.

### Templates — `client.templates`

`create(name:, html:, **)` · `list` · `get(id)` · `update(id, **)` · `delete(id)` · `preview(html:, format:, variables:)` · `preview_by_id(id, variables:)` · `format(html:, format:)` · `test_render(html:, format:, variables:)` · `test_send(id, to:, from:, subject:, variables:)`.

### Audiências e contatos — `client.audiences`

`create(name:, description:)` · `list(limit:, offset:)` · `pages` · `get(id)` · `update(id, name:, description:, active:)` · `delete(id)`.

`client.audiences.contacts`: `create(audience_id, email:, first_name:, last_name:, metadata:)` · `list(audience_id, limit:, offset:)` · `pages(audience_id)` · `bulk_add(audience_id, contacts:)` (até 10 000) · `update(audience_id, contact_id, **)` · `delete(audience_id, contact_id)`.

### Campanhas — `client.broadcasts`

`create(audience_id:, from_email:, **)` · `list(**filtros)` · `pages` · `get(id)` · `send(id)` · `test_send(id, to:, variables:)` · `cancel(id)`. Toda operação exige chave com permissão `full_access`. Não existe remoção de campanha.

### Remetentes — `client.senders`

`create(email:, display_name:)` · `list` · `verify(token:)` · `delete(id)`.

### Supressões — `client.suppressions`

`create(email:, reason:, expires_at:)` · `list(**filtros)` · `pages` · `get(id)` · `delete(id)` · `reactivate(id)` · `bulk_create(suppressions:)` (até 1000). As rotas usam o **id** da supressão, nunca o e-mail.

### Webhooks — `client.webhooks`

`create(url:, events:, description:)` (o `secret` vem só nesta resposta) · `list(status:)` · `get(id)` · `update(id, **)` · `toggle(id, status:)` · `delete(id)` · `rotate_secret(id)` · `list_deliveries(id, **filtros)` · `test(id)`.

### Estatísticas — `client.stats`

`get(domain_id:, tag:, start_date:, end_date:, granularity:, period:, email_type:)`.

## 🔔 Webhooks

`CoffeeMail::Webhook` verifica a assinatura das entregas. Ele não depende do `Client` nem de chave de API:

```ruby
class CoffeeMailWebhooksController < ApplicationController
  skip_forgery_protection

  def create
    result = CoffeeMail::Webhook.from_rack(request, secret: ENV.fetch("COFFEEMAIL_WEBHOOK_SECRET"))
    return head(:bad_request) if result.failure?

    Rails.logger.info("#{result.data.event_type}: #{result.data.data}")
    head(:no_content)
  end
end
```

- A assinatura (`x-webhook-signature`) é `sha256=` + HMAC-SHA256 em hexadecimal de `timestamp + "." + idempotency_key + "." + corpo bruto`, comparada em tempo constante.
- Entregas com `x-webhook-timestamp` fora da janela (padrão 300 s, `tolerance:`) são rejeitadas para impedir replay.
- Já leu o corpo? Use `CoffeeMail::Webhook.verify(payload:, headers:, secret:)` (Boolean) ou `construct_event(...)` (`Response` com o evento ou `WebhookVerificationError#reason`). Nunca re-serialize o JSON antes de verificar.
- `x-webhook-idempotency-key` muda a cada tentativa de entrega e não serve para deduplicar retentativas. O corpo (`event_type`, `webhook_id`, `data`) não traz o id do e-mail.
- Veja um app Rack completo em [`examples/webhook_rack.rb`](examples/webhook_rack.rb).

## 🔖 Versionamento e releases

- [Versionamento Semântico](https://semver.org/lang/pt-BR/). A política da casa vale desde a `0.x`: a API pública só recebe **adições e depreciações**, nunca remoção ou renomeação. O CI compara as assinaturas RBS com as da última versão publicada (`bin/check-api-compat`).
- A versão está em `CoffeeMail::VERSION` e vai no `User-Agent` (`coffeemail-ruby/<versão>`).
- Uma tag `vX.Y.Z` dispara o workflow de release: confere a tag com `VERSION` e o `CHANGELOG.md`, roda os gates, publica no RubyGems (trusted publishing) e cria a GitHub Release.
- Mudanças ficam no [CHANGELOG.md](CHANGELOG.md).

## 🧪 Testes e qualidade

```bash
bundle exec rake                          # todos os gates
bundle exec rubocop --only CoffeeMail     # regras da casa (sem else/case/comentários fora do YARD, profundidade ≤ 3)
bundle exec steep check                   # tipos (RBS em sig/)
bundle exec rspec                         # testes, cobertura mínima de 85% de linhas e 78% de branches
bin/check-spec-coverage --report          # matriz de rastreabilidade SPEC × testes
bin/smoke-test                            # instala o .gem gerado em um diretório limpo
bundle exec bundler-audit check --update
```

- O desenvolvimento é guiado por especificação: todo requisito de [`specs/SPEC.md`](specs/SPEC.md) tem teste, e o nome de cada teste começa pelo ID do requisito.
- Os testes usam um transporte falso injetado por `transport:`; nenhum teste acessa a API.
- `spec/conformance` valida as requisições das 64 operações contra `openapi/product.json` e falha se alguma operação do spec ficar sem método.
- `spec/webhook_spec.rb` roda os vetores compartilhados de `spec/fixtures/webhook_vectors.json`, gerados pelo assinador da API.

Para atualizar o snapshot do spec:

```bash
bin/sync-spec                                       # do spec público
COFFEEMAIL_OPENAPI_SPEC=caminho/product.json bin/sync-spec
bin/sync-spec --check                               # só verifica divergência
```

## 🗂️ Estrutura do repositório

```
├── lib/coffeemail.rb                    ponto de entrada
├── lib/coffeemail/client.rb             Client, introspecção
├── lib/coffeemail/response.rb, errors.rb  envelope e hierarquia de erros
├── lib/coffeemail/resources/            um arquivo por recurso
├── lib/coffeemail/models/               modelos de resposta (Data)
├── lib/coffeemail/webhook.rb            verificação de assinatura
├── lib/coffeemail/internal/             transporte, rotas, headers, i18n, backoff, paginação
├── sig/                                 assinaturas RBS (Steep)
├── rubocop/cop/coffeemail/              cops das regras da casa
├── specs/SPEC.md                        especificação (requisitos RB-*)
├── spec/                                testes RSpec, fixtures e conformidade
├── openapi/product.json                 snapshot do OpenAPI de produto
├── bin/, tools/                         gates: versão, rastreabilidade, compatibilidade, assinaturas
└── examples/                            exemplos executáveis
```

## 🤝 Contribuição

Veja o [CONTRIBUTING.md](CONTRIBUTING.md). Vulnerabilidades: siga o [SECURITY.md](SECURITY.md).

## 🔗 Projetos relacionados

| Repositório | Papel |
| --- | --- |
| [coffee-mail-sdk-node](https://github.com/Coffee-Mail/coffee-mail-sdk-node) | SDK oficial Node.js/TypeScript (`@coffeemail/node`) |
| [coffee-mail-sdk-python](https://github.com/Coffee-Mail/coffee-mail-sdk-python) | SDK oficial Python (`coffeemail`) |
| [coffee-mail-sdk-php](https://github.com/Coffee-Mail/coffee-mail-sdk-php) | SDK oficial PHP (`coffeemail/coffeemail-php`) |
| [coffee-mail-sdk-java](https://github.com/Coffee-Mail/coffee-mail-sdk-java) | SDK oficial Java (`br.com.coffeemail:coffeemail-java`) |
| [coffee-mail-sdk-go](https://github.com/Coffee-Mail/coffee-mail-sdk-go) | SDK oficial Go (`github.com/Coffee-Mail/coffee-mail-sdk-go`) |
| **coffee-mail-sdk-ruby** (você está aqui) | SDK oficial Ruby (`coffeemail`) |
| [coffee-mail-rails](https://github.com/Coffee-Mail/coffee-mail-rails) | Integração Rails (`coffeemail-rails`): delivery method do ActionMailer e webhooks |
| [coffee-mail-laravel](https://github.com/Coffee-Mail/coffee-mail-laravel) | Integração Laravel (`coffeemail/coffeemail-laravel`) |
| [coffee-mail-sdk-workbench](https://github.com/Coffee-Mail/coffee-mail-sdk-workbench) | Bancada de validação dos SDKs por spec |

## 📄 Licença

[MIT](LICENSE).

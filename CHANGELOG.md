# Changelog

Todas as mudanças relevantes deste projeto são documentadas aqui. O formato segue o [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/) e o projeto adota o [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [Não lançado]

### Adicionado

- `CoffeeMail::Client` com as 61 operações da API de produto, no mesmo contrato dos SDKs Node.js, Python, PHP, Java e Go: `emails`, `domains`, `templates`, `audiences` (com `contacts`), `broadcasts`, `senders`, `suppressions`, `webhooks` e `stats`, além da introspecção da chave com cache de 5 minutos.
- Envelope `CoffeeMail::Response` (`data`/`error`, desestruturação, pattern matching e `unwrap!`) e hierarquia de erros com código canônico, `api_code`, `details` e `request_id`.
- Mensagens de erro locais em português (padrão) e inglês.
- `CoffeeMail::Webhook` (`verify`, `construct_event`, `from_rack`), compatível com a assinatura enviada pela API e validado pelos vetores compartilhados.
- `CoffeeMail::RetryPolicy` (opt-in) e `pages` para percorrer listas paginadas.
- `CoffeeMail.with_request_id` para propagar `x-request-id`.
- Assinaturas RBS em `sig/`, verificadas pelo Steep em modo estrito.
- Especificação em `specs/SPEC.md`, com rastreabilidade entre requisitos e testes verificada no CI.

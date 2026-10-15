# AGENTS.md

Orientações para agentes de código neste repositório. As regras completas estão no [CONTRIBUTING.md](CONTRIBUTING.md) e o comportamento esperado está em [`specs/SPEC.md`](specs/SPEC.md).

## Comandos

```bash
bundle exec rake                         # todos os gates
bundle exec rubocop --only CoffeeMail    # regras da casa
bundle exec steep check                  # tipos (RBS em sig/)
bundle exec rspec                        # testes + cobertura
bundle exec rspec spec/conformance       # contrato com openapi/product.json
bin/check-spec-coverage [--report]       # rastreabilidade SPEC × testes
bin/check-version-sync                   # VERSION × gemspec × User-Agent × CHANGELOG
bin/check-api-compat                     # API pública contra a última tag
bin/sync-spec [--check]                  # snapshot do OpenAPI (COFFEEMAIL_OPENAPI_SPEC)
```

## Fluxo

- Spec-driven: requisito no `specs/SPEC.md` → teste com o ID no nome → implementação. Nunca implemente comportamento sem requisito.
- `spec/` é do RSpec; `specs/` é da especificação.

## Regras inegociáveis

- Contrato idêntico aos SDKs Node.js, Python, PHP, Java e Go: mesmas operações, códigos de erro canônicos, headers, mensagens locais e esquema de webhook.
- API pública: só adicionar e depreciar. Nunca renomear, remover ou mudar assinatura.
- Sem opção de URL base. Testes injetam `transport:` com o `FakeTransport` de `spec/support`.
- Zero dependências de runtime (só a biblioteca padrão).
- Sem comentários fora do YARD de API pública; sem `else`/`elsif`/`case`; profundidade ≤ 3; `rescue`/`raise` só nos adaptadores isolados; sem saída em console; sem números e textos mágicos.
- Toda operação devolve `CoffeeMail::Response`; só `unwrap!` levanta exceção.
- `emails.send` e `broadcasts.send` escondem `Object#send`: use `public_send`/`__send__` em código dinâmico.
- Retry só em erro de rede, 5xx e 429 (exceto `PLAN_QUOTA_EXCEEDED`), e nunca em `POST` sem chave de idempotência.
- A chave de API e o segredo de webhook nunca aparecem em mensagens de erro ou em `inspect`/`to_s`.
- Documentação, commits e PRs em português do Brasil; código em inglês.
- Este repositório é público: não cite nem linke repositórios privados.

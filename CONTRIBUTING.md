# Contribuindo com o CoffeeMail Ruby SDK

Obrigado pelo interesse! Este guia resume como propor mudanças.

## Antes de começar

- Bugs e sugestões: abra uma issue usando um dos modelos.
- Vulnerabilidades: **não** abra issue pública; siga o [SECURITY.md](SECURITY.md).
- Mudanças grandes ou que alterem a API pública: abra uma issue para discussão antes do PR.

## Ambiente

- Ruby 3.3 ou superior.
- `bundle install` e depois `bundle exec rake`, que precisa passar antes de qualquer PR. Ele roda as regras da casa, o RuboCop, o RBS com Steep em modo strict, os testes com cobertura mínima (85% de linhas e 78% de branches), a conformidade das requisições com o OpenAPI, a rastreabilidade do SPEC, a sincronização de versão e a compatibilidade da API pública.

## Desenvolvimento guiado por especificação

O comportamento do SDK é definido em [`specs/SPEC.md`](specs/SPEC.md), com requisitos numerados (`RB-*`).

1. Comportamento novo ou alterado começa por um requisito no SPEC, com critério de aceite verificável.
2. O teste vem antes do código e o nome começa pelo ID: `it "RB-ERR-07 401 sem message usa o catálogo local"`.
3. `bin/check-spec-coverage` falha se um requisito ficar sem teste ou se um teste citar um ID inexistente. `bin/check-spec-coverage --report` mostra a matriz de rastreabilidade.

## Regras de código

O SDK segue as regras de código da CoffeeMail, verificadas pelos cops em `rubocop/cop/coffeemail/`:

- Código em inglês; documentação, issues, commits e PRs em português do Brasil.
- Sem comentários, exceto o magic comment `frozen_string_literal` e YARD na API pública. `# rubocop:disable` também é comentário: exceções ficam no `.rubocop.yml`, com justificativa.
- Sem `else`, `elsif` e `case`: use retorno antecipado ou tabelas (`Hash#fetch`).
- Profundidade máxima 3, contando blocos.
- `rescue` e `raise` só nos adaptadores isolados (transporte, parse de JSON, `Response#unwrap!` e validação de opções). Erros de API e de rede voltam no envelope `CoffeeMail::Response`.
- Sem números e textos mágicos: use constantes congeladas.
- Sem saída em console na biblioteca.
- Cada comportamento novo vem com testes: caminho feliz e ao menos dois caminhos de erro.

## Compatibilidade

Mudanças na API pública devem **adicionar e depreciar**, nunca renomear ou remover. `bin/check-api-compat` compara as assinaturas RBS de `sig/` com as da última versão publicada.

## Mudanças no contrato da API

Quando o OpenAPI da API mudar, rode `bin/sync-spec` (ou `COFFEEMAIL_OPENAPI_SPEC=<arquivo ou URL> bin/sync-spec`), ajuste o SPEC, os recursos e os modelos, e mantenha o teste de conformidade verde.

## Commits e PRs

- Mensagens em português, diretas, no formato `tipo(escopo): descrição` (ex.: `feat(emails): expõe metadata no envio`).
- Atualize o `CHANGELOG.md` na seção "Não lançado".
- Preencha o modelo de PR.

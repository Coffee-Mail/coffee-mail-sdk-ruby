# frozen_string_literal: true

module CoffeeMail
  module Models
    # Registro DNS a publicar.
    DnsRecord = Internal::Model.define(type: :string, host: :string, value: :string, ttl: :integer,
                                       is_infrastructure: :boolean)

    # Resultado de `domains.create`.
    CreatedDomain = Internal::Model.define(id: :string, name: :string, status: :string,
                                           dkim_records_to_publish: [DnsRecord])

    # Identidade de envio no provedor.
    SendingIdentity = Internal::Model.define(provider: :string, state: :string, last_synced_at: :time)

    # Domínio em `domains.list`.
    DomainSummary = Internal::Model.define(
      id: :string, name: :string, status: :string, status_reason: :string, dkim_selector: :string,
      dkim_public_key: :string, verified_at: :time, last_check_at: :time, created_at: :time
    )

    # Resultado de `domains.list` (sem paginação).
    DomainList = Internal::Model.define(domains: [DomainSummary])

    # Rotação de DKIM pendente (`domains.rotate_dkim` e `DomainDetail#dkim_rotation`).
    DkimRotation = Internal::Model.define(domain_id: :string, selector: :string, started_at: :time,
                                          record: DnsRecord)

    # Host próprio apontado por CNAME para a plataforma (return-path e domínio de rastreamento).
    CustomHostStatus = Internal::Model.define(host: :string, target: :string, verified: :boolean,
                                              verified_at: :time, record: DnsRecord)

    # Detalhe de um domínio.
    DomainDetail = Internal::Model.define(
      id: :string, name: :string, status: :string, status_reason: :string, sending_identity: SendingIdentity,
      dkim_selector: :string, dkim_public_key: :string, verified_at: :time, last_check_at: :time,
      created_at: :time, dns_records_to_publish: [DnsRecord], dkim_rotation: DkimRotation,
      return_path: CustomHostStatus, tracking_domain: CustomHostStatus, tracking_domains_available: :boolean
    )

    # Checagem DNS de `domains.verify`.
    DnsCheck = Internal::Model.define(ok: :boolean, resolution: :string, expected: :string, got: :string,
                                      matches: :strings)

    # Conjunto de checagens de `domains.verify`.
    DomainChecks = Internal::Model.define(spf: DnsCheck, dkim: DnsCheck, dmarc: DnsCheck, ownership: DnsCheck,
                                          infrastructure_spf: DnsCheck)

    # Resultado de `domains.verify`.
    DomainVerification = Internal::Model.define(
      id: :string, name: :string, status: :string, status_reason: :string, verified_at: :time,
      checks: DomainChecks, required_checks: :strings, sending_identity: SendingIdentity
    )

    # Checagem de `domains.get_health`.
    HealthCheck = Internal::Model.define(ok: :boolean, expected: :string, got: :string)

    # Resultado de `domains.get_health`.
    DomainHealth = Internal::Model.define(domain_id: :string, domain: :string, status: :string, spf: HealthCheck,
                                          dkim: HealthCheck, dmarc: HealthCheck, checked_at: :time)

    # Resultado de `domains.get_warmup_status`.
    DomainWarmup = Internal::Model.define(
      domain_id: :string, current_day: :integer, daily_quota: :integer, sent_today: :integer,
      remaining_today: :integer, quota_used_percent: :integer, last_send_date: :string, status: :string,
      total_days: :integer, started_at: :time, completed_at: :time
    )

    # Resultado de `domains.delete`.
    DeletedDomain = Internal::Model.define(ok: :boolean)
  end
end

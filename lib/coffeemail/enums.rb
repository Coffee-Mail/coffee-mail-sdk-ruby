# frozen_string_literal: true

module CoffeeMail
  # Status de um e-mail: `queued`, `processing`, `sent`, `delivered`, `bounced`, `complained`, `failed`,
  # `skipped`, `scheduled` e `cancelled`. Os enums são abertos: valores novos da API chegam como String.
  module EmailStatus
    Internal::Enum.define(self, %w[queued processing sent delivered bounced complained failed skipped scheduled
                                   cancelled])
  end

  # Categoria do envio: `transactional` e `broadcast`.
  module EmailType
    Internal::Enum.define(self, %w[transactional broadcast])
  end

  # Disposição de um anexo: `attachment` e `inline`.
  module AttachmentDisposition
    Internal::Enum.define(self, %w[attachment inline])
  end

  # Status de um domínio: `pending`, `verified` e `failed`.
  module DomainStatus
    Internal::Enum.define(self, %w[pending verified failed])
  end

  # Motivo do status de um domínio: `dns_records_missing`, `provider_pending` e `provider_failed`.
  module DomainStatusReason
    Internal::Enum.define(self, %w[dns_records_missing provider_pending provider_failed])
  end

  # Saúde de um domínio: `healthy`, `warning` e `critical`.
  module DomainHealthStatus
    Internal::Enum.define(self, %w[healthy warning critical])
  end

  # Resultado da consulta DNS: `found`, `absent` e `unknown`.
  module DnsResolution
    Internal::Enum.define(self, %w[found absent unknown])
  end

  # Status de um broadcast: `draft`, `scheduled`, `sending`, `sent`, `failed` e `cancelled`.
  module BroadcastStatus
    Internal::Enum.define(self, %w[draft scheduled sending sent failed cancelled])
  end

  # Motivo de uma supressão: `manual`, `bounce`, `isp_block`, `mailbox_not_found`, `complaint` e `unsubscribe`.
  module SuppressionReason
    Internal::Enum.define(self, %w[manual bounce isp_block mailbox_not_found complaint unsubscribe])
  end

  # Origem de uma supressão: `manual` e `auto`.
  module SuppressionSource
    Internal::Enum.define(self, %w[manual auto])
  end

  # Status de uma supressão: `active`, `expired` e `inactive`.
  module SuppressionStatus
    Internal::Enum.define(self, %w[active expired inactive])
  end

  # Formato de um template: `html` e `react`.
  module TemplateFormat
    Internal::Enum.define(self, %w[html react])
  end

  # Status de um webhook: `active`, `paused` e `disabled`. `toggle` aceita só `active` e `paused`.
  module WebhookStatus
    Internal::Enum.define(self, %w[active paused disabled])
  end

  # Status de uma entrega de webhook: `pending`, `success`, `failed` e `exhausted`.
  module WebhookDeliveryStatus
    Internal::Enum.define(self, %w[pending success failed exhausted])
  end

  # Granularidade das estatísticas: `day`, `week` e `month`.
  module StatsGranularity
    Internal::Enum.define(self, %w[day week month])
  end
end

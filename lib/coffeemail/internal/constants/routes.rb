# frozen_string_literal: true

module CoffeeMail
  module Internal
    module Constants
      module Routes
        EMAILS = "/emails"
        EMAILS_BATCH = "/emails/batch"
        EMAILS_TAGS = "/emails/tags"
        EMAIL = "/emails/%s"
        EMAIL_EVENTS = "/emails/%s/events"
        EMAIL_CANCEL = "/emails/%s/cancel"
        EMAIL_RESEND = "/emails/%s/resend"
        DOMAINS = "/domains"
        DOMAIN = "/domains/%s"
        DOMAIN_VERIFY = "/domains/%s/verify"
        DOMAIN_HEALTH = "/domains/%s/health"
        DOMAIN_WARMUP = "/domains/%s/warmup"
        TEMPLATES = "/templates"
        TEMPLATE = "/templates/%s"
        TEMPLATES_PREVIEW = "/templates/preview"
        TEMPLATES_FORMAT = "/templates/format"
        TEMPLATES_TEST_RENDER = "/templates/test-render"
        TEMPLATE_TEST_SEND = "/templates/%s/test-send"
        AUDIENCES = "/audiences"
        AUDIENCE = "/audiences/%s"
        CONTACTS = "/audiences/%s/contacts"
        CONTACTS_BULK = "/audiences/%s/contacts/bulk"
        CONTACT = "/audiences/%s/contacts/%s"
        BROADCASTS = "/broadcasts"
        BROADCAST = "/broadcasts/%s"
        BROADCAST_SEND = "/broadcasts/%s/send"
        BROADCAST_TEST_SEND = "/broadcasts/%s/test-send"
        BROADCAST_CANCEL = "/broadcasts/%s/cancel"
        SENDERS = "/senders"
        SENDERS_VERIFY = "/senders/verify"
        SENDER = "/senders/%s"
        SENDER_RESEND_VERIFICATION = "/senders/%s/resend-verification"
        SUPPRESSIONS = "/suppressions"
        SUPPRESSIONS_BULK = "/suppressions/bulk"
        SUPPRESSION = "/suppressions/%s"
        SUPPRESSION_REACTIVATE = "/suppressions/%s/reactivate"
        WEBHOOKS = "/webhooks"
        WEBHOOK = "/webhooks/%s"
        WEBHOOK_ROTATE_SECRET = "/webhooks/%s/rotate-secret"
        WEBHOOK_DELIVERIES = "/webhooks/%s/deliveries"
        WEBHOOK_TEST = "/webhooks/%s/test"
        STATS = "/stats"
        API_KEY_INTROSPECTION = "/auth/me/api-key"
      end
    end
  end
end

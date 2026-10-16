# frozen_string_literal: true

module CoffeeMail
  module Internal
    module Fields
      ATTACHMENT = {
        filename: "filename", content: "content", content_type: "contentType", disposition: "disposition",
        cid: "cid"
      }.freeze
      TAG = { name: "name", value: "value" }.freeze
      SEND_EMAIL = {
        from: ["from", :address], to: ["to", :addresses], cc: ["cc", :addresses], bcc: ["bcc", :addresses],
        reply_to: ["replyTo", :address], subject: "subject", html: "html", text: "text", headers: "headers",
        attachments: ["attachments", ATTACHMENT], template_id: "templateId", variables: "variables",
        email_type: "emailType", suppression_category: "suppressionCategory", tags: ["tags", TAG],
        scheduled_at: "scheduledAt", metadata: "metadata"
      }.freeze
      LIST_EMAILS = {
        status: "status", recipient: "recipient", from_email: "fromEmail", subject_contains: "subjectContains",
        api_key_id: "apiKeyId", tag: "tag", from: "from", to: "to", after: "after", limit: "limit"
      }.freeze
      TEMPLATE = {
        name: "name", alias: "alias", subject: "subject", preheader: "preheader", html: "html",
        content_json: "contentJson", text_payload: "textPayload", variables: "variables", format: "format",
        source_locale: "sourceLocale", is_active: "isActive"
      }.freeze
      TEMPLATE_RENDER = { html: "html", format: "format", variables: "variables" }.freeze
      TEMPLATE_TEST_SEND = { to: "to", from: "from", subject: "subject", variables: "variables" }.freeze
      OFFSET_PAGE = { limit: "limit", offset: "offset" }.freeze
      AUDIENCE = { name: "name", description: "description", active: "active" }.freeze
      CONTACT = { email: "email", first_name: "firstName", last_name: "lastName", metadata: "metadata" }.freeze
      CONTACTS_BULK = { contacts: ["contacts", CONTACT] }.freeze
      BROADCAST = {
        audience_id: "audienceId", from_email: "fromEmail", template_id: "templateId", subject: "subject",
        html: "html", text: "text", reply_to: "replyTo", scheduled_at: "scheduledAt", variables: "variables"
      }.freeze
      LIST_BROADCASTS = { status: "status", from: "from", to: "to", after: "after", limit: "limit" }.freeze
      BROADCAST_TEST_SEND = { to: "to", variables: "variables" }.freeze
      SENDER = { email: "email", display_name: "displayName" }.freeze
      SENDER_VERIFY = { token: "token" }.freeze
      SUPPRESSION = { email: "email", reason: "reason", expires_at: "expiresAt" }.freeze
      SUPPRESSIONS_BULK = { suppressions: ["suppressions", { email: "email", reason: "reason" }.freeze] }.freeze
      LIST_SUPPRESSIONS = {
        status: "status", reason: "reason", source: "source", category: "category", after: "after", limit: "limit"
      }.freeze
      WEBHOOK = { url: "url", events: "events", description: "description" }.freeze
      WEBHOOK_TOGGLE = { status: "status" }.freeze
      LIST_WEBHOOKS = { status: "status" }.freeze
      LIST_DELIVERIES = {
        event_type: "eventType", status: "status", from: "from", to: "to", limit: "limit"
      }.freeze
      STATS = {
        domain_id: "domainId", tag: "tag", start_date: "startDate", end_date: "endDate",
        granularity: "granularity", period: "period", email_type: "emailType"
      }.freeze
      DOMAIN = { name: "name" }.freeze
    end
  end
end

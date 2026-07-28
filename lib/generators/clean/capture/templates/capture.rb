require "base64"

# Domain-positioned, domain-blind: translates an utterance or a photo into
# registry commands, discovering the vocabulary from the registry at runtime.
# The interpreter never bypasses the registry; children land in the ledger.
class Capture
  PAYLOAD = %i[utterance image].freeze

  PROMPT = <<~PROMPT.freeze
    Translate the user's request into application commands.
    Emit only commands allowed by the schema, using the user's own words for
    values. Fill every payload field; use null when the request does not say.
    Payload values are human-readable words taken from the request — never
    identifiers, slugs or underscores. Emit only the commands the request
    itself asks for; never invent ids or follow-up commands. When a field
    only allows fixed options, pick the one closest in meaning to the
    user's words, whatever language they wrote in.
    If a photo is provided, emit one command per item you identify.
  PROMPT

  def call(payload)
    interpreted = interpret(payload)
    return Result.err(:interpreter_down) if interpreted.nil?

    commands = Array(interpreted[:commands]).filter_map { |raw| normalize(raw) }
    return Result.err(:nothing_understood) if commands.empty?

    if payload[:image].present?
      propose(commands, payload[:image])
    else
      execute(commands, parent_id: payload[:_command_id])
    end
  end

  private

  def interpret(payload)
    Infer.structured(
      CaptureSchema.build(with_regions: payload[:image].present?),
      prompt: prompt_for(payload),
      images: image_data(payload[:image])
    )
  end

  # Photos get an explicit request and no few-shot: the text-shaped
  # examples invite parroting when there is no utterance to ground them.
  def prompt_for(payload)
    if payload[:image].present?
      request = payload[:utterance].presence || "Catalog every item you can identify in the photo."
      "#{PROMPT}\nEach command carries region: the item's bounding box in the
photo as integers normalized 0-1000, origin at the top-left corner.\n" \
        "Commands available:\n#{menu}\n\nRequest: #{request}"
    else
      "#{PROMPT}\nCommands available:\n#{menu}\n#{examples}\n\nRequest: #{payload[:utterance]}"
    end
  end

  # The grammar constrains; the menu explains. Derived from the registry,
  # so it stays domain-blind.
  def menu
    Registry::COMMANDS.filter_map do |name, handler|
      next if handler == self.class

      "- #{name}(#{handler::PAYLOAD.join(', ')}): #{name.humanize.downcase}"
    end.join("\n")
  end

  # Few-shot collected from the handlers that declare EXAMPLE — domain
  # content stays in the domain's files; capture only gathers it.
  def examples
    shots = Registry::COMMANDS.flat_map do |name, handler|
      next [] if handler == self.class

      shots_for(handler).map do |example|
        %(Request: "#{example[:request]}" -> {"commands":[{"name":"#{name}","payload":#{example[:payload].to_json}}]})
      end
    end
    shots << %(Request: "how is the weather today?" -> {"commands":[]})
    "Examples:\n#{shots.join("\n")}"
  end

  def shots_for(handler)
    return handler::EXAMPLES if handler.const_defined?(:EXAMPLES, false)
    return [handler::EXAMPLE] if handler.const_defined?(:EXAMPLE, false)

    []
  end

  def image_data(signed_id)
    return nil if signed_id.blank?

    blob = ActiveStorage::Blob.find_signed(signed_id)
    blob && [Base64.strict_encode64(blob.download)]
  end

  def normalize(raw)
    name = raw[:name].to_s
    handler = Registry.command(name)
    return nil if handler.nil? || handler == self.class

    { name: name, payload: (raw[:payload] || {}).slice(*handler::PAYLOAD).compact, region: raw[:region] }
  end

  # High blast radius (a photo can yield many guessed rows): propose, let
  # the human confirm through the ordinary commands. The captured image is
  # forwarded to commands that accept :photo, plus a default :notes marking
  # the origin — both by PAYLOAD convention, never by domain knowledge.
  def propose(commands, image)
    photo_url = Rails.application.routes.url_helpers
                     .rails_service_blob_path(image, "capture.jpg")
    proposals = commands.map do |command|
      keys = Registry.command(command[:name])::PAYLOAD
      merged = command[:payload].compact
      merged = { photo: image }.merge(merged) if keys.include?(:photo)
      if keys.include?(:notes) && merged[:notes].blank?
        merged[:notes] = I18n.t("commands.capture.note", default: "Captured from photo")
      end
      { name: command[:name], payload: merged, region: command[:region], photo_url: photo_url }
    end
    Result.ok({ photo: image, photo_url: photo_url, proposals: proposals },
              notice: I18n.t("commands.capture.proposed", default: nil))
  end

  # Low blast radius (one utterance, few commands): commit directly.
  def execute(commands, parent_id:)
    landed = commands.map { |command| execute_child(command, parent_id) }
    ok, err = landed.partition { |land| land[:ok] }
    Result.ok({ ok: ok, err: err },
              notice: I18n.t("commands.capture.done", default: nil))
  end

  def execute_child(command, parent_id)
    child = Command.create!(name: command[:name], payload: command[:payload], parent_id: parent_id)
    result = Registry.command(child.name).new
                     .call(child.payload.symbolize_keys.merge(_command_id: child.id))
    child.update!(status: result.ok? ? "done" : "failed", result: result.as_json)
    { command_id: child.id, name: child.name, ok: result.ok?, result: result.as_json }
  end
end

# The allowlist becomes the decoding grammar: a JSON schema derived from the
# registry (command names + PAYLOAD keys) plus enum values introspected from
# the entities. An unknown command is unrepresentable, not merely unlikely.
module CaptureSchema
  # Bounding box in the photo: integers normalized to 0-1000, origin at the
  # top-left. Only the photo path asks for regions.
  REGION = {
    type: "object",
    properties: {
      x: { type: "integer", minimum: 0, maximum: 1000 },
      y: { type: "integer", minimum: 0, maximum: 1000 },
      w: { type: "integer", minimum: 0, maximum: 1000 },
      h: { type: "integer", minimum: 0, maximum: 1000 },
    },
    required: %w[x y w h],
    additionalProperties: false,
  }.freeze

  def self.build(with_regions: false)
    # Entities must be loaded for enum introspection (dev/test lazy-load).
    Rails.autoloaders.main.eager_load_dir(Rails.root.join("app/entities"))
    {
      type: "object",
      properties: { commands: { type: "array", items: { anyOf: command_schemas(with_regions) } } },
      required: ["commands"],
      additionalProperties: false,
    }
  end

  def self.command_schemas(with_regions)
    Registry::COMMANDS.filter_map do |name, handler|
      next if handler == Capture

      keys = handler::PAYLOAD.reject { |key| attachment?(key) }
      properties = {
        name: { enum: [name] },
        payload: {
          type: "object",
          properties: keys.index_with { |key| property_for(key) },
          required: keys.map(&:to_s),
          additionalProperties: false,
        },
      }
      required = %w[name payload]
      if with_regions
        properties[:region] = REGION
        required << "region"
      end
      { type: "object", properties: properties, required: required, additionalProperties: false }
    end
  end

  def self.property_for(key)
    values = enum_values(key)
    return { enum: values + [nil] } if values
    return { type: %w[integer null] } if key.to_s.end_with?("_id")

    case column_for(key)&.type
    when :boolean then { type: %w[boolean null] }
    when :integer then { type: %w[integer null] }
    else { type: %w[string number boolean null] }
    end
  end

  # Uploads are never inferable: the model must not invent blob references.
  def self.attachment?(key)
    ApplicationRecord.descendants.any? do |entity|
      entity.respond_to?(:attachment_reflections) && entity.attachment_reflections.key?(key.to_s)
    end
  end

  def self.column_for(key)
    ApplicationRecord.descendants.each do |entity|
      column = entity.columns_hash[key.to_s]
      return column if column
    end
    nil
  end

  def self.enum_values(key)
    ApplicationRecord.descendants.each do |entity|
      return entity.defined_enums[key.to_s].keys if entity.defined_enums.key?(key.to_s)
    end
    nil
  end
end

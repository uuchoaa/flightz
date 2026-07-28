# frozen_string_literal: true

class Components::HiddenInput < Components::Base
  def initialize(target:)
    @target = target
  end

  def view_template
    input(type: "hidden", data: target_data(@target))
  end
end

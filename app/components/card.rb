# frozen_string_literal: true

class Components::Card < Components::Base
  def initialize(title = nil)
    @title = title
  end

  def view_template(&)
    div(class: "border border-gray-200 rounded-2xl p-6 mb-8") do
      h2(class: "text-lg font-medium mb-5") { @title } if @title
      yield if block_given?
    end
  end
end

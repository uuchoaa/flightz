# frozen_string_literal: true

class Components::PageHeading < Components::Base
  def initialize(title, subtitle: nil)
    @title = title
    @subtitle = subtitle
  end

  def view_template
    h1(class: "text-4xl font-semibold") { @title }
    p(class: "text-gray-500 mt-1 mb-6") { @subtitle } if @subtitle
  end
end

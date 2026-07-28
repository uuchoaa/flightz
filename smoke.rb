#!/usr/bin/env ruby
# frozen_string_literal: true

# End-to-end smoke test for the flights domain, no Rails server needed.
# Runs one real round-trip search through the whole seam (live tokens via
# headless Chrome, HTTP to Google, parse) and prints the narrated steps and
# the offers — the same pipeline the SSE screen drives.
#
#   ruby smoke.rb                       # GRU -> REC, a month out
#   ruby smoke.rb JFK LAX 2026-10-26 2026-11-02

require_relative "config/environment"

origin      = ARGV[0] || "GRU"
destination = ARGV[1] || "REC"
departure   = ARGV[2] || Date.current.next_month.strftime("%Y-%m-%d")
back        = ARGV[3] || (Date.current.next_month + 10).strftime("%Y-%m-%d")

puts "Search #{origin} -> #{destination}  #{departure} / #{back}"
puts "-" * 60

log = ->(key, **data) do
  detail = data.map { |k, v| "#{k}=#{v.is_a?(Array) ? v.join(',') : v}" }.join(" ")
  puts "  · #{I18n.t("flights.step.#{key}", default: key.to_s, **data)}#{" [#{detail}]" unless data.empty?}"
end

result = Flights::Queries::Search.new.call(
  { origin:, destination:, departure_date: departure, return_date: back }, log:
)

puts "-" * 60
if result[:error]
  puts "ERROR: #{result[:error]} — #{result[:details]}"
  exit 1
end

flights = result[:best_flights]
puts "#{flights.size} flights"
flights.first(15).each do |f|
  printf("  %-8s %-7s %s -> %s  %4dmin  stops=%d  R$%s\n",
         f[:airline], f[:flight_number], f[:departure_airport][:code],
         f[:arrival_airport][:code], f[:duration], f[:stops], f[:price])
end

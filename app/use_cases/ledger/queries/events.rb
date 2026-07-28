module Ledger
  module Queries
    # call(params) -> as_json-ready data (params: status, name, limit)
    # The ledger, newest first: every command with its outcome, for the
    # logs screen. Children carry parent_id so batches group visually.
    class Events
      COLUMNS = %i[id name status level payload result parent_id created_at].freeze

      def call(params)
        scope = ::Command.order(id: :desc)
        scope = scope.where(status: params[:status]) if params[:status].present?
        scope = scope.where(name: params[:name]) if params[:name].present?
        scope = scope.where(level: params[:level]) if params[:level].present? && params[:level] != "all"
        limit = params[:limit].to_i
        limit = 100 unless (1..500).cover?(limit)
        scope.limit(limit).map { |command| command.as_json(only: COLUMNS) }
      end
    end
  end
end

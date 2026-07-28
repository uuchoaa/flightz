module Api
  # The entire read side: pure V-shape, dispatched to query objects.
  class QueriesController < ApplicationController
    def show
      query = Registry.query(params[:name]) or return head(:not_found)
      render json: query.new.call(query_params)
    end

    private

    def query_params
      params.except(:controller, :action, :name, :format).permit!.to_h.symbolize_keys
    end
  end
end

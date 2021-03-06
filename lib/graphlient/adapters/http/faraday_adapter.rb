require 'faraday'
require 'faraday_middleware'

module Graphlient
  module Adapters
    module HTTP
      class FaradayAdapter < Adapter
        def execute(document:, operation_name:, variables:, context:)
          response = connection.post do |req|
            req.headers.merge!(context[:headers] || {})
            req.body = {
              query: document.to_query_string,
              operationName: operation_name,
              variables: variables
            }.to_json
          end
          response.body
        rescue Faraday::ConnectionFailed => e
          raise Graphlient::Errors::ConnectionFailedError, e
        rescue Faraday::TimeoutError => e
          raise Graphlient::Errors::TimeoutError, e
        rescue Faraday::ClientError => e
          raise Graphlient::Errors::FaradayServerError, e
        end

        def connection
          @connection ||= Faraday.new(url: url, headers: headers) do |c|
            c.use Faraday::Response::RaiseError
            c.request :json
            c.response :json

            configure_http_options(c.options)

            if block_given?
              yield c
            else
              http_adapter = Faraday::Adapter::NetHttp
              c.use http_adapter
            end
          end
        end
      end
    end
  end
end

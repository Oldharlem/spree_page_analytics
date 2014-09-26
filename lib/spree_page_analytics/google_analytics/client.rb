require 'google/api_client'
require 'date'

module SpreePageAnalytics
  module GoogleAnalytics
    class Client
      def initialize(service_account_email, key_file, key_secret, profile_id)
        @API_VERSION = 'v3'
        @CACHED_API_FILE = "analytics-#{@API_VERSION}.cache"

        # Update these to match your own apps credentials
        @service_account_email = service_account_email #'389871615598-l0b1if50ukrq871jqe72ih3itq1njjkr@developer.gserviceaccount.com' # Email of service account
        @key_file = key_file #'config/privatekey.p12' # File containing your private key
        @key_secret = key_secret #'notasecret' # Password to unlock private key
        @profile_id = profile_id #'14428743' # Analytics profile ID.

        @client = Google::APIClient.new(
          :application_name => 'Spree Page Analytics',
          :application_version => '1.0.0')
        @authorized = false
      end

      def authorized?
        @authorized
      end

      def authorize
        # Load our credentials for the service account
        key = Google::APIClient::KeyUtils.load_from_pkcs12(@key_file, @key_secret)
        @client.authorization = Signet::OAuth2::Client.new(
          :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
          :audience => 'https://accounts.google.com/o/oauth2/token',
          :scope => 'https://www.googleapis.com/auth/analytics.readonly',
          :issuer => @service_account_email,
          :signing_key => key)

        # Request a token for our service account
        @client.authorization.fetch_access_token!

        @analytics = nil
        # Load cached discovered API, if it exists. This prevents retrieving the
        # discovery document on every run, saving a round-trip to the discovery service.
        if File.exists? @CACHED_API_FILE
          File.open(@CACHED_API_FILE) do |file|
            @analytics = Marshal.load(file)
          end
        else
          @analytics = @client.discovered_api('analytics', @API_VERSION)
          File.open(@CACHED_API_FILE, 'w') do |file|
            Marshal.dump(@analytics, file)
          end
        end

        @authorized = true
      end

      def get_data(start_date, end_date, dimensions, metrics, filters, sort)

        # Set up query parameters
        start_date ||= DateTime.now.prev_month
        start_date = start_date.strftime("%Y-%m-%d")
        end_date ||= DateTime.now
        end_date = end_date.strftime("%Y-%m-%d")
        dimensions ||= "ga:landingPagePath,ga:date"
        metrics ||= "ga:sessions,ga:transactions,ga:transactionRevenue,ga:transactionRevenuePerSession"
        sort ||= "ga:landingPagePath"

        # Request as many pages as necessary for complete data set
        rows = []
        page_to_request = 1
        requested = 0
        result = nil
        begin
          start_index = page_to_request + requested
          result = execute_request @profile_id, start_date, end_date, dimensions, metrics, filters, sort, start_index
          rows += result.data.rows
          requested += 1000
          page_to_request += 1
        end until requested >= result.data.total_results
        {:columns => result.data.column_headers, :rows => rows}
      end

      def execute_request profile_id, start_date, end_date, dimensions, metrics, filters, sort, start_index
        params = { 
          'ids' => "ga:" + @profile_id,
          'start-date' => start_date,
          'end-date' => end_date,
          'dimensions' => dimensions,
          'metrics' => metrics,
          'start-index' => start_index
        }
        params['filters'] = filters if filters
        params['sort'] = sort if sort

        @client.execute(:api_method => @analytics.data.ga.get, :parameters => params)
      end
    end
  end
end
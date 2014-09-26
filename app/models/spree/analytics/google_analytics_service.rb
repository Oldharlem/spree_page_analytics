module Spree
  module Analytics
    class GoogleAnalyticsService < Spree::Preferences::Configuration      
      preference :view_id, :string, :default => ""
      preference :key_file, :string, :default => ""
      preference :key_secret, :string, :default => ""
      preference :service_account_email, :string, :default => ""

      def initialize
        @client = SpreePageAnalytics::GoogleAnalytics::Client.new(
          preferred_service_account_email,
          preferred_key_file,
          preferred_key_secret,
          preferred_view_id
        )
      end

      def create_snapshots(date=nil)
        
        # Request data from Google
        if !@client.authorized?
          @client.authorize
        end
        yesterday = Time.now - 1.day
        date ||= yesterday
        start_date ||= date.beginning_of_day
        end_date ||= date.end_of_day
        dimensions = "ga:landingPagePath"
        metrics = "ga:sessions,ga:transactions,ga:transactionRevenue"
        sort = "ga:landingPagePath"
        filters = "ga:landingPagePath=@/t/,ga:landingPagePath=@/products/,ga:landingPagePath==/"
        result = @client.get_data(start_date, end_date, dimensions, metrics, filters, sort)

        # Create snapshot for each row
        result[:rows].each do |row|
          Spree::PageTrafficSnapshot.create(
            :page => row[0], 
            :sessions => row[1], 
            :transactions => row[2],
            :revenue => row[3],
            :begin => start_date,
            :end => end_date
          )
        end
      end
    end
  end
end
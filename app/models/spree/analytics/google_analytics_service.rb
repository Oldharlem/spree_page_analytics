module Spree
  module Analytics
    class GoogleAnalyticsService < Spree::Preferences::Configuration
      
      preference :view_id, :string, :default => ""
      preference :key_file, :string, :default => ""
      preference :key_secret, :string, :default => ""
      preference :service_account_email, :string, :default => ""

      attr_accessible :view_id, :key_file, :key_secret, :service_account_email

      def initialize
        @client = SpreePageAnalytics::GoogleAnalytics::Client.new
      end

      def create_snapshots(date)
        binding.pry
        # Request data from Google
        if !@client.authorized?
          @client.authorize
        end
        yesterday = Time.now - 1.day
        start_date ||= yesterday.beginning_of_day
        end_date ||= yesterday.end_of_day
        dimensions = "ga:landingPagePath"
        metrics = "ga:sessions,ga:transactions,ga:transactionRevenue"
        filters = ""
        sort = "ga:landingPagePath"
        result = @client.get_data(start_date, end_date, dimensions, metrics, filters, sort)

        # Create snapshot for each row
        result.data.rows.each do |row|
          Spree::PageTrafficSnapshot.create{
            :page => row[0], 
            :sessions => row[1], 
            :transactions => row[2],
            :revenue => row[3],  
            :begin => start_date, 
            :end => end_date
          }
        end
      end
    end
  end
end
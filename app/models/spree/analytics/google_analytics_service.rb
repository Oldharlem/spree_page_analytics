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

      def create_snapshots(start_date=nil, end_date=nil)
        if !@client.authorized?
          @client.authorize
        end
        start_date ||= begin
          newest_snapshot = Spree::PageTrafficSnapshot.order("begin DESC").first
          newest_snapshot_start = newest_snapshot ? newest_snapshot.begin.beginning_of_day + 1.day : nil
          four_months_ago = Time.now.beginning_of_day - 4.months
          if newest_snapshot_start
            [newest_snapshot_start, four_months_ago].max
          else
            four_months_ago
          end
        end
        end_date ||= Time.now.end_of_day - 1.day
        date = start_date
        while date < end_date
          create_snapshots_for_date(date)
          date += 1.day
        end
      end

      def create_snapshots_for_date(date)
        dimensions = "ga:landingPagePath"
        metrics = "ga:sessions,ga:transactions,ga:transactionRevenue"
        sort = "ga:landingPagePath"
        filters = "ga:landingPagePath=@/t/,ga:landingPagePath=@/products/,ga:landingPagePath==/"
        result = @client.get_data(date.beginning_of_day, date.end_of_day, dimensions, metrics, filters, sort)
        result[:rows].each do |row|
          Spree::PageTrafficSnapshot.create(
            :page => row[0], 
            :sessions => row[1], 
            :transactions => row[2],
            :revenue => row[3],
            :begin => date.beginning_of_day,
            :end => date.end_of_day
          )
        end
      end
    end
  end
end
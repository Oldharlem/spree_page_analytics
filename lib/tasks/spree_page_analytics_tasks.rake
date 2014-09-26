namespace :spree_page_analytics do
  task :create_snapshots => [:environment] do |t, args|
    Spree::PageAnalytics::GoogleAnalyticsService.create_snapshots
  end
end
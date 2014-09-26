require 'spree_core'

module Spree
  module PageAnalytics
    def self.config(&block)
      yield(Spree::PageAnalytics::Config)
    end
  end
end

require 'spree_page_analytics/engine'

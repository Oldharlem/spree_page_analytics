module Spree
  class PageTrafficSnapshot < ActiveRecord::Base
    attr_accessible :page, :sessions, :revenue, :transactions, :begin, :end, :max_cpc, :avg_cpc
  end
end
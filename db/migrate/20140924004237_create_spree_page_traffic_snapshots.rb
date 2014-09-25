class CreateSpreePageTrafficSnapshots < ActiveRecord::Migration
  def change
    create_table :spree_page_traffic_snapshots do |t|
      t.string :page
      t.integer :sessions
      t.integer :transactions
      t.integer :revenue
      t.datetime :begin
      t.datetime :end
      t.decimal :max_cpc, :precision => 8, :scale => 2
      t.decimal :avg_cpc, :precision => 8, :scale => 2
      t.integer :paid_clicks
      t.integer :ad_spend
    end
  end
end

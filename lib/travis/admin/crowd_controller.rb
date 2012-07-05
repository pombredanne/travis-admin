require 'travis/admin/controller'
require 'csv'

module Travis::Admin
  class CrowdController < Travis::Admin::Controller
    set prefix: '/crowd', title: 'Crowd Funding'

    before do
      crowd_db = Sequel.connect(settings.crowd_db)
      @orders  = crowd_db[:orders].join(:users, id: :user_id).join(:addresses, addressable_id: :orders__id, kind: 'billing')

      if params[:start_date]
        start_date = Time.parse("#{params[:start_date]} 00:00:00 +0200")
        @orders.filter! { orders__created_at >= start_date }
      end

      if params[:end_date]
        end_date = Time.parse("#{params[:end_date]} 23:59:59 +0200")
        @orders.filter! { orders__created_at <= end_date }
      end
    end

    get '/' do
      slim :index
    end

    get '/packages.:format' do
      @orders.group_and_count!(:subscription, :package, :country, :add_vat) { date_trunc('day', :orders__created_at).as(:date) }
      @orders.select_more! { sum(total).as(:total) }

      as_csv
    end

    get '/vat_ids.:format' do
      @orders.filter! 'vatin IS NOT NULL'
      @orders.filter! "vatin != ''"
      @orders.select!(:subscription, :package, :country, :add_vat, :total) { date_trunc('day', :orders__created_at).as(:date) }
      @orders.select_more! :users__name, :orders__id, :orders__vatin

      as_csv
    end

    def columns
      columns = @orders.columns.dup
      columns.delete(:date)
      columns
    end

    def values(order)
      order[:add_vat]      = !!order[:add_vat]
      order[:subscription] = !!order[:subscription]
      order[:country]      = "Unknown" if order[:country].to_s.empty?
      order[:total]        = order[:total].to_s[0..-3] + '.' + order[:total].to_s[-2..-1]
      [order[:date].strftime("%Y-%m-%d"), *order.values_at(*columns)]
    end

    def as_csv
      content_type params[:format].to_sym
      CSV.generate do |csv|
        csv << ["date", *columns.map(&:to_s)]
        @orders.each do |order|
          csv << values(order)
        end
      end
    end
  end
end

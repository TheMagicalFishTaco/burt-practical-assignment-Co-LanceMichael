require 'csv'
require 'json'

module SalesReport
    SHOP_HEADERS = [:shop_name, :shop_city, :total_units_sold, :total_revenue, :total_transactions].freeze
    TRANSACTION_HEADERS = [:date, :country, :channel, :category, :shop_name, :shop_city, :units_sold, :revenue, :transactions].freeze

    #Loads the requested file
    def self.load_json(path)
        JSON.parse(File.read(path), symbolize_names: true)
    end

    #turns the stores.json file into a lookup table
    def self.build_shop_lookup(store_data)
        store_data.each_with_object({}) do |shop, lookup|
            lookup[shop[:shop_id]] = shop  
        end         
    end


    #organizes data acquired from transactions.json by shop_id, for store summary
    def self.group_store_data(transaction_data, shops_by_id)
        transaction_data.group_by { |r| r[:shop_id] }.filter_map do |shop_id, records|
            #Cover the edge case transactions with a malformed shop ID, just put its name and city to N/A
            shop = shops_by_id[shop_id] || {name: "N/A", city: "N/A"}
            {
                shop_name: shop[:name],
                shop_city: shop[:city],
                total_units_sold: records.sum { |r| r[:units_sold] || 0 },
                total_revenue: records.sum { |r| (r[:revenue] || 0).to_f },
                total_transactions: records.size
            }
        end              
    end

    #just goes through the list of transactions and puts the data in the right header.
    #everything but the shop name and shop city can be taken straight from the transaction (r) itself.
    def self.group_transaction_data(transaction_data, shops_by_id)
          transaction_data.filter_map do |r|
                 shop = shops_by_id[r[:shop_id]] || {name: "N/A", city: "N/A"}
                 {
                    date: r[:date],
                    country: r[:country],
                    channel: r[:channel],
                    category: r[:category],
                    shop_name: shop[:name],
                    shop_city: shop[:city],
                    units_sold: r[:units_sold],
                    revenue: r[:revenue],
                    transactions: r[:transactions]
                 }
          end
    end

    #Generates the CSV File with the requested data and headers
    def self.write_csv(rows, headers, path)
        CSV.open(path, "wb") do |csv|
            csv << headers
            rows.each { |row| csv << row.values_at(*headers) }
        end  
    end
end

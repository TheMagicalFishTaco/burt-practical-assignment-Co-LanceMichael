require 'csv'
require 'json'

module SalesReport
    SHOP_HEADERS = [:shop_name, :shop_city, :total_units_sold, :total_revenue, :total_transactions].freeze

    #Loads the requested file
    def self.load_json(path)
        JSON.parse(File.read(path), symbolize_names: true)
    end

    #turns the stores.json file into a lookup table
    def self.build_shop_lookup(store_data)
        shops_by_id = store_data.each_with_object({}) do |shop, lookup|
            lookup[shop[:shop_id]] = shop  
        end         
        shops_by_id["S999"] ||= { shop_id: "S999", name: "Online", city: "N/A"}
        shops_by_id
    end


    #organizes data acquired from transactions.json
    def self.group_store_data(transaction_data, shops_by_id)
        transaction_data.group_by { |r| r[:shop_id] }.filter_map do |shop_id, records|
            shop = shops_by_id[shop_id]
            if shop.nil?
                    puts "Skipping unknown"
                    next  
            end
            {
                shop_name: shop[:name],
                shop_city: shop[:city],
                total_units_sold: records.sum { |r| r[:units_sold] || 0 },
                total_revenue: records.sum { |r| (r[:revenue] || 0).to_f },
                total_transactions: records.size
            }
        end              
    end


    #Generates the CSV File
    def self.write_csv(rows, headers, path)
        CSV.open(path, "wb") do |csv|
            csv << headers
            rows.each { |row| csv << row.values_at(*headers) }
        end  
    end
end

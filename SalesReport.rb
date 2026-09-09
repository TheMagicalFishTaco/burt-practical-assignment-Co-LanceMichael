require 'csv'
require 'json'

store_data = JSON.parse(File.read("data/stores.json"), symbolize_names: true)
transaction_data = JSON.parse(File.read("data/transactions.json"), symbolize_names: true)


shops_by_id = store_data.each_with_object({}) do |shop, lookup|
    lookup[shop[:shop_id]] = shop  
end

shops_by_id["S999"] ||= { id: "S999", name: "Online", city: "N/A"}

unmatched = transaction_data.map { |r| r[:shop_id] }.uniq - shops_by_id.keys
puts "Unmatched shop_ids: #{unmatched.inspect}"

shop_headers = [:shop_name, :shop_city, :total_units_sold, :total_revenue, :total_transactions]
grouped_store_data = transaction_data.group_by { |r| r[:shop_id] }.filter_map do |shop_id, records|
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


CSV.open("store_summary.csv", "wb") do |csv|
  csv << shop_headers
  grouped_store_data.each do |row|
    csv << shop_headers.map { |h| row[h] }
  end
end

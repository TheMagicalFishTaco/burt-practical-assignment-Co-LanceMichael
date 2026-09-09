require 'csv'


stores_file = File.open("data/stores.json")
transactions_file = File.open("data/transactions.json")





data = [
{ name: "Alice", age: 30 },
{ name: "Bob", age: 25 }
]
CSV.open("transaction_detail.csv", "wb") do |csv|
  csv << ["name", "age"] # Write headers
  data.each do |record|
    csv << [record[:name], record[:age]]
  end
end
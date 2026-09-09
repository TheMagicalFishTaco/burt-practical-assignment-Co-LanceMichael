require_relative 'sales_report'

store_data = SalesReport.load_json("data/stores.json")
transaction_data = SalesReport.load_json("data/transactions.json")

shops_by_id = SalesReport.build_shop_lookup(store_data)
grouped_store_data = SalesReport.group_store_data(transaction_data, shops_by_id)

SalesReport.write_csv(grouped_store_data,SalesReport::SHOP_HEADERS, "store_summary.csv")
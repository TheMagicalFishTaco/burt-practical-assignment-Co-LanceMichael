# Burt Intelligence Practical Assignment - Co, Lance Michael O.

## Code Walkthrough
This project reads the JSON files in the data folder and generates 2 CSV files, a per-store report and a transaction breakdown report.

There are 3 ruby files in the project.
- run_sales_report.rb - the main executable script
- sales_report.rb - the core backend module
- sales_report_tests.rb - the unit test suite, uses Minitest

sales_report.rb follows a basic flow of take inputs -> build lookup -> organize data -> output csvs.
- load_json - reads the json files in the path specified by run_sales_report.rb
- build_shop_lookup - uses the stores.json's shop_id as a primary key to make a lookup table for later
- group_store_data - groups the transaction data by shop_id for the store summary csv
- group_transaction_data - goes through all the transactions and organizes the data according to the requested headers
- sanitize_csv - runs on group_store_data and group_transaction_data, extra precaution for potential CSV injections in the shop_name and shop_city fields
- write_csv - generates the csv, taking the relevant data, headers, and file name to be generated


## Instructions to Run

### Requirements
- Ruby 3.4.10
- Bundler

### Setup
bundle install

### Run Program
bundle exec ruby run_sales_report.rb
This produces "store_summary.csv" and "transaction_breakdown.csv" in the root directory

bundle exec ruby sales_report_tests.rb
This will run the unit tests that cover the following cases alongside testing the functionality of sales_report's methods:
- file input, make sure that the file exists
- file input, make sure that the file has the correct data

- data processing, make sure that null/invalid data is handled correctly
- data processing, cover type errors (integers, floats, strings)
- data processing, cover CSV injection possibilities

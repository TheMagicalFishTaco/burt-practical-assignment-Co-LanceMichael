require 'minitest/autorun'
require 'tempfile'
require_relative 'sales_report'

=begin
Test cases to cover
- file input, make sure that the file exists
- file input, make sure that the file has the correct data

- data processing, make sure that null/invalid data is handled correctly
- data processing, cover type errors (integers, floats, strings)
- data processing, cover CSV injection possibilities
=end

class LoadFileTests < Minitest::Test
    def test_asserts_when_file_does_not_exist
	    assert_raises(Errno::ENOENT) do
	      SalesReport.load_json("data/does_not_exist.json")
	    end
    end

    def test_parses_valid_json_into_symbol_keyed_hashes
	    Tempfile.create(['stores','.json']) do |file|
	      file.write('[{"shop_id": "S100", "name": "Main St"}]')
	      file.flush

	      result = SalesReport.load_json(file.path)

	      assert_equal 1, result.size
	      assert_equal "S100", result.first[:shop_id]

	    end
    end

    def test_raises_on_malformed_json
	    Tempfile.create(['bad','.json']) do |file|
		file.write('{not valid json}')
		file.flush

		assert_raises(JSON::ParserError) {SalesReport.load_json(file.path)}
	    end
    end
end

class BuildShopLookupTest < Minitest::Test
    def test_indexes_shops_by_shop_id
      store_data = [{shop_id: "S100", name: "Main St", city: "New York"}]
      lookup = SalesReport.build_shop_lookup(store_data)

      assert_equal "Main St", lookup["S100"][:name]
    end

    def test_registers_online_shop
      lookup = SalesReport.build_shop_lookup([])

      refute_nil lookup["S999"]
      assert_equal "Online", lookup["S999"][:name]
    end
end

class GroupStoreDataTest < Minitest::Test
    def setup
	    @shops_by_id =
	    {
	      "S100" => {shop_id: "S100", name: "Main St", city: "New York"},
	      "S999" => {shop_id: "S999", name: "Online", city: "N/A"},
	    }
    end

    #Tests for null or invalid data

    def test_missing_units_sold_and_revenue_default_to_zero
	    transactions = [{shop_id:"S100", units_sold: nil, revenue: nil}]
	    row = SalesReport.group_store_data(transactions, @shops_by_id).first

	    assert_equal 0, row[:total_units_sold]
	    assert_equal 0.0, row[:total_revenue]
    end

    def test_unmatched_shop_id_goes_to_placeholder
	    transactions = [{shop_id:"S404", units_sold: 9, revenue: "99.99"}]
	    row = SalesReport.group_store_data(transactions, @shops_by_id).first

	    refute_nil row
	    assert_equal "N/A", row[:shop_name]
	    assert_equal "N/A", row[:shop_city]
	    assert_equal 9, row[:total_units_sold]
    end

    def test_multiple_transactions_for_same_shop
	    transactions =
	    [
	      {shop_id: "S100", units_sold:1, revenue: "1.00"},
	      {shop_id: "S100", units_sold:2, revenue: "2.00"}
	    ]
	    row = SalesReport.group_store_data(transactions, @shops_by_id).first

	    assert_equal 3, row[:total_units_sold]
	    assert_equal 3.00, row[:total_revenue]
	    assert_equal 2, row[:total_transactions]
    end

    def test_empty_transactions_list
	    assert_empty SalesReport.group_store_data([], @shops_by_id)
    end


    #Tests for type errors
    def test_string_revenue_becomes_float
	    transactions = [{shop_id: "S100", units_sold:1, revenue:9.99 }]
	    row SalesReport.group_store_data(transactions, @shops_by_id).first

	    assert_equal 9.99, row[:total_revenue]
    end

    def test_string_units_sold_becomes_int
	    transactions = [{shop_id: "S100", units_sold:1, revenue:9.99 }]
	    row SalesReport.group_store_data(transactions, @shops_by_id).first

	    assert_equal 1, row[:total_units_sold]
    end

    def test_mixed_types_sum_correctly
	    transactions =
	    [
	      {shop_id: "S100", units_sold:"1", revenue: 1.00},
	      {shop_id: "S100", units_sold:2, revenue: "2.00"}
	    ]
	    row SalesReport.group_store_data(transactions, @shops_by_id).first

	    assert_equal 3, row[:total_units_sold]
	    assert_equal 3.00, row[:total_revenue]
	    assert_equal 2, row[:total_transactions]
    end
end

class GroupTransactionDataTest < Minitest::Test
        def setup
                @shops_by_id = {
                "S100" => { shop_id: "S100", name: "Main St", city: "New York" }
                }
        end

        def test_shop_fields_come_from_lookup_and_transaction_fields_come_from_record
                transactions = [{ shop_id: "S100", date: "2024-03-01", country: "US", channel: "online",
                                category: "home", units_sold: 10, revenue: "9.99" }]
                row = SalesReport.group_transaction_data(transactions, @shops_by_id).first

                assert_equal "Main St", row[:shop_name]
                assert_equal "New York", row[:shop_city]
                assert_equal "2024-03-01", row[:date]
                assert_equal "US", row[:country]
        end

        def test_unmatched_shop_id_goes_to_placeholder
                transactions = [{ shop_id: "S999", date: "2024-03-01", units_sold: 1, revenue: "1.00" }]
                row = SalesReport.group_transaction_data(transactions, @shops_by_id).first

                refute_nil row
                assert_equal "N/A", row[:shop_name]
                assert_equal "N/A", row[:shop_city]
        end

        def test_missing_units_sold_and_revenue_default_to_zero
                transactions = [{ shop_id: "S100", units_sold: nil, revenue: nil }]
                row = SalesReport.group_transaction_data(transactions, @shops_by_id).first

                assert_equal 0, row[:units_sold]
                assert_equal 0.0, row[:revenue]
        end

        def test_string_revenue_and_units_sold_are_handled
                transactions = [{ shop_id: "S100", units_sold: "1", revenue: "9.99" }]
                row = SalesReport.group_transaction_data(transactions, @shops_by_id).first

                assert_equal 1, row[:units_sold]
                assert_equal 9.99, row[:revenue]
        end

        def test_each_transaction_produces_its_own_row_not_grouped
                transactions = [
                { shop_id: "S100", units_sold: 1, revenue: 1.0 },
                { shop_id: "S100", units_sold: 2, revenue: 2.0 }
                ]
                result = SalesReport.group_transaction_data(transactions, @shops_by_id)

                assert_equal 2, result.size
        end
end

class CsvInjectionTest < Minitest::Test
	def test_formula_prefix_in_shop_name_does_nothing
		shops = { "S999" => {shop_id: "S999", name:"=cmd|'/C calc'!A1", city: "New York" } }
		transactions = [{shop_id: "S999", units_sold:1, revenue:1.0}]

		row = SalesReport.group_store_data(transactions, shops).first

		refute_match(/\A[=+\-@]/, row[:shop_name])
	end

	def test_formula_prefix_in_shop_city_does_nothing
		shops = { "S999" => { shop_id: "S999", name: "Main St", city: "+1+1" } }
		transactions = [{ shop_id: "S999", units_sold: 1, revenue: 1.0 }]

		row = SalesReport.group_store_data(transactions, shops).first

		refute_match(/\A[=+\-@]/, row[:shop_city])
	end

	def test_normal_shop_name_is_left_unchanged
		shops = { "S100" => { shop_id: "S100", name: "Main St", city: "New York" } }
		transactions = [{ shop_id: "S100", units_sold: 1, revenue: 1.0 }]

		row = SalesReport.group_store_data(transactions, shops).first

		assert_equal "Main St", row[:shop_name]
	end
end

class WriteCsvTest < Minitest::Test
	def test_writes_headers_in_order
		rows = [{ shop_name: "Main St", shop_city: "New York", total_units_sold: 1, total_revenue: 9.99, total_transactions: 1 }]

		Tempfile.create(['output', '.csv']) do |file|
		SalesReport.write_csv(rows, SalesReport::SHOP_HEADERS, file.path)

		lines = CSV.read(file.path)
		assert_equal ["shop_name", "shop_city", "total_units_sold", "total_revenue", "total_transactions"], lines.first
		assert_equal ["Main St", "New York", "1", "9.99", "1"], lines.last
	end
	end
end




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

    def test_missing_units_sold_and_revenue_default_to_zero
            transactions = [{shop_id:"S100", units_sold: nil, revenue: nil}]
            row = SalesReport.group_store_data(transactions, @shops_by_id).first

            assert_equal 0, row[:total_units_sold]
            assert_equal 0.0, row[:total_revenue]
    end

    def test_unmatched_shop_id_is_skipped_not_raised
            transactions = [{shop_id:"S404", units_sold: 9, revenue: "99.99"}]
            result = SalesReport.group_store_data(transactions, @shops_by_id)

            assert_empty result
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

    

end




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


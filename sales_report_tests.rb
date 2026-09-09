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
end
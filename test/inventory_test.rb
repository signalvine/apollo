require 'minitest/autorun'
require 'apollo'

class InventoryTest < MiniTest::Test

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @cwd = File.expand_path('..', __FILE__)
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  def test_inventory_load
    test = Apollo::Cluster.new :filename => "#{@cwd}/full_inventory.yml"
    assert_equal test.get_host(:postgres).nil?, false
  end

  def test_nonexistant_file
    begin
      Apollo::Cluster.new :filename => 'whatisthis?'
      fail 'Failed to throw exception for non-existant file'
    rescue Errno::ENOENT
      assert true
    end
  end

  def test_empty_invetory
    begin
      Apollo::Cluster.new :filename => "#{@cwd}/empty_inventory.yml"
      fail 'Failed to throw exception for empty inventory'
    rescue
      assert true
    end
  end

  def test_empty_host
    begin
      Apollo::Cluster.new :filename => "#{@cwd}/empty_hosts.yml"
      fail 'Failed to throw exception for empty hosts entry'
    rescue
      assert true
    end
  end
end

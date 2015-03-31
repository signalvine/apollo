require 'minitest/autorun'
require 'apollo'
require 'bunny'

class InventoryTest < MiniTest::Test

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @cwd = File.expand_path('..', __FILE__)
    @apollo = Apollo::Cluster.new :filename => "#{File.expand_path('..', __FILE__)}/vagrant_inventory.yml"
    @conn = Bunny.new("amqp://apollo:apollo@192.168.100.4:5672")
    @conn.start
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    @conn.close
  end

  def test_empty_receive
    ch = @conn.create_channel
    x = ch.direct('test')
    listener = @apollo.create_rmq_listener(:vagrant, 'test', 'test')
    messages = listener.get_all
    assert_equal messages.length, 0
  end

  def test_receive_message
    ch = @conn.create_channel
    x = ch.direct('test')
    listener = @apollo.create_rmq_listener(:vagrant, 'test', 'test2')
    x.publish('{"message": "message"}', :routing_key => 'test2')
    sleep 0.000122072
    message = listener.get_all
    assert_equal message.length, 1
    assert_equal message[0]['message'], 'message'
  end

  def test_message_order
    ch = @conn.create_channel
    x = ch.direct('test3')
    listener = @apollo.create_rmq_listener(:vagrant, 'test3', 'test3')
    x.publish('{"order": 1}', :routing_key => 'test3')
    x.publish('{"order": 2}', :routing_key => 'test3')
    sleep 0.000244144
    messages = listener.get_all
    assert_equal messages.length, 2
    assert_equal messages[0]['order'], 1
    assert_equal messages[1]['order'], 2
  end

end

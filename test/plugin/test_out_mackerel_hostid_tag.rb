# coding: utf-8

require 'helper'

class MackerelHostidTagOutputTest < Test::Unit::TestCase

  def setup
    Fluent::Test.setup
  end

  HOSTID_PATH = File.dirname(__FILE__) + "/hostid"

  CONFIG = %[
    type mackerel_hostid_tag
    hostid_path #{HOSTID_PATH}
    add_to tag
  ]

  CONFIG_RECORD = %[
    type mackerel_hostid_tag
    hostid_path #{HOSTID_PATH}
    add_to record
    key_name mackerel_hostid
  ]

  CONFIG_RECORD_NO_KEY_NAME = %[
    type mackerel_hostid_tag
    hostid_path #{HOSTID_PATH}
    add_to record
  ]

  CONFIG_TAG_REMOVE = %[
    type mackerel_hostid_tag
    hostid_path #{HOSTID_PATH}
    add_to record
    key_name mackerel_hostid
    remove_prefix test
  ]

  CONFIG_TAG_ADD = %[
    type mackerel_hostid_tag
    hostid_path #{HOSTID_PATH}
    add_to record
    key_name mackerel_hostid
    add_prefix mackerel
  ]

  CONFIG_TAG_BOTH = %[
    type mackerel_hostid_tag
    hostid_path #{HOSTID_PATH}
    add_to record
    key_name mackerel_hostid
    remove_prefix test
    add_prefix mackerel
  ]

  CONFIG_TAG_BOTH_TAG = %[
    type mackerel_hostid_tag
    hostid_path #{HOSTID_PATH}
    add_to tag
    remove_prefix test
    add_prefix mackerel
  ]

  def create_driver(conf = CONFIG, tag='test')
    Fluent::Test::OutputTestDriver.new(Fluent::MackerelHostidTagOutput, tag).configure(conf)
  end

  def test_configure

    assert_raise(Fluent::ConfigError) {
      d = create_driver('')
    }

    assert_raise(Fluent::ConfigError) {
      d = create_driver(CONFIG_RECORD_NO_KEY_NAME)
    }

    d = create_driver()
    assert_equal d.instance.instance_variable_get(:@hostid), 'xyz'
    assert_equal d.instance.instance_variable_get(:@add_to), 'tag'

    d = create_driver(CONFIG_RECORD)
    assert_equal d.instance.instance_variable_get(:@hostid), 'xyz'
    assert_equal d.instance.instance_variable_get(:@add_to), 'record'
    assert_equal d.instance.instance_variable_get(:@key_name), 'mackerel_hostid'

  end

  def test_write_tag

    d = create_driver()

    ENV["TZ"]="Asia/Tokyo"
    t = Time.strptime('2014-08-10 15:00:00', '%Y-%m-%d %T')
    d.run do
      d.emit({'val1' => 1, 'val2' => 2, 'val3' => 3, 'val4' => 4}, t)
      d.emit({'val1' => 5, 'val2' => 6, 'val3' => 7, 'val4' => 8}, t)
    end

    emits = d.emits
    assert_equal 2, emits.length
    assert_equal 'test.xyz', emits[0][0] # tag
    assert_equal 1407650400, emits[0][1] # time
    assert_equal 4, emits[0][2].length # record
    assert_equal 1, emits[0][2]["val1"] # record
    assert_equal 2, emits[0][2]["val2"] # record
    assert_equal 3, emits[0][2]["val3"] # record
    assert_equal 4, emits[0][2]["val4"] # record

    assert_equal 'test.xyz', emits[1][0] # tag
    assert_equal 1407650400, emits[1][1] # time
    assert_equal 4, emits[1][2].length # record
    assert_equal 5, emits[1][2]["val1"] # record
    assert_equal 6, emits[1][2]["val2"] # record
    assert_equal 7, emits[1][2]["val3"] # record
    assert_equal 8, emits[1][2]["val4"] # record
  end

  def test_write_record

    d = create_driver(CONFIG_RECORD)

    ENV["TZ"]="Asia/Tokyo"
    t = Time.strptime('2014-08-10 15:00:00', '%Y-%m-%d %T')
    d.run do
      d.emit({'val1' => 1, 'val2' => 2, 'val3' => 3, 'val4' => 4}, t)
      d.emit({'val1' => 5, 'val2' => 6, 'val3' => 7, 'val4' => 8}, t)
    end

    emits = d.emits
    assert_equal 2, emits.length
    assert_equal 'test', emits[0][0] # tag
    assert_equal 1407650400, emits[0][1] # time
    assert_equal 5, emits[0][2].length # record length
    assert_equal 1, emits[0][2]["val1"] # record
    assert_equal 2, emits[0][2]["val2"] # record
    assert_equal 3, emits[0][2]["val3"] # record
    assert_equal 4, emits[0][2]["val4"] # record
    assert_equal "xyz", emits[0][2]["mackerel_hostid"] # record

    assert_equal 'test', emits[1][0] # tag
    assert_equal 1407650400, emits[1][1] # time
    assert_equal 5, emits[1][2].length # record length
    assert_equal 5, emits[1][2]["val1"] # record
    assert_equal 6, emits[1][2]["val2"] # record
    assert_equal 7, emits[1][2]["val3"] # record
    assert_equal 8, emits[1][2]["val4"] # record
    assert_equal "xyz", emits[1][2]["mackerel_hostid"] # record
  end

  def test_write_record_remove_prefix

    d = create_driver(CONFIG_TAG_REMOVE, 'test.service')

    ENV["TZ"]="Asia/Tokyo"
    t = Time.strptime('2014-08-10 15:00:00', '%Y-%m-%d %T')
    d.run do
      d.emit({'val1' => 1, 'val2' => 2, 'val3' => 3, 'val4' => 4}, t)
    end

    emits = d.emits
    assert_equal 1, emits.length
    assert_equal 'service', emits[0][0] # tag
    assert_equal 1407650400, emits[0][1] # time
    assert_equal 5, emits[0][2].length # record length
    assert_equal 1, emits[0][2]["val1"] # record
    assert_equal 2, emits[0][2]["val2"] # record
    assert_equal 3, emits[0][2]["val3"] # record
    assert_equal 4, emits[0][2]["val4"] # record
    assert_equal "xyz", emits[0][2]["mackerel_hostid"] # record

  end

  def test_write_record_add_prefix

    d = create_driver(CONFIG_TAG_ADD)

    ENV["TZ"]="Asia/Tokyo"
    t = Time.strptime('2014-08-10 15:00:00', '%Y-%m-%d %T')
    d.run do
      d.emit({'val1' => 1, 'val2' => 2, 'val3' => 3, 'val4' => 4}, t)
    end

    emits = d.emits
    assert_equal 1, emits.length
    assert_equal 'mackerel.test', emits[0][0] # tag
    assert_equal 1407650400, emits[0][1] # time
    assert_equal 5, emits[0][2].length # record length
    assert_equal 1, emits[0][2]["val1"] # record
    assert_equal 2, emits[0][2]["val2"] # record
    assert_equal 3, emits[0][2]["val3"] # record
    assert_equal 4, emits[0][2]["val4"] # record
    assert_equal "xyz", emits[0][2]["mackerel_hostid"] # record

  end

  def test_write_record_remove_and_add_prefix

    d = create_driver(CONFIG_TAG_BOTH, 'test.service')

    ENV["TZ"]="Asia/Tokyo"
    t = Time.strptime('2014-08-10 15:00:00', '%Y-%m-%d %T')
    d.run do
      d.emit({'val1' => 1, 'val2' => 2, 'val3' => 3, 'val4' => 4}, t)
    end

    emits = d.emits
    assert_equal 1, emits.length
    assert_equal 'mackerel.service', emits[0][0] # tag
    assert_equal 1407650400, emits[0][1] # time
    assert_equal 5, emits[0][2].length # record length
    assert_equal 1, emits[0][2]["val1"] # record
    assert_equal 2, emits[0][2]["val2"] # record
    assert_equal 3, emits[0][2]["val3"] # record
    assert_equal 4, emits[0][2]["val4"] # record
    assert_equal "xyz", emits[0][2]["mackerel_hostid"] # record

  end

  def test_write_tag_remove_and_add_prefix

    d = create_driver(CONFIG_TAG_BOTH_TAG, 'test.service')

    ENV["TZ"]="Asia/Tokyo"
    t = Time.strptime('2014-08-10 15:00:00', '%Y-%m-%d %T')
    d.run do
      d.emit({'val1' => 1, 'val2' => 2, 'val3' => 3, 'val4' => 4}, t)
    end

    emits = d.emits
    assert_equal 1, emits.length
    assert_equal 'mackerel.service.xyz', emits[0][0] # tag
    assert_equal 1407650400, emits[0][1] # time
    assert_equal 4, emits[0][2].length # record length
    assert_equal 1, emits[0][2]["val1"] # record
    assert_equal 2, emits[0][2]["val2"] # record
    assert_equal 3, emits[0][2]["val3"] # record
    assert_equal 4, emits[0][2]["val4"] # record

  end

end
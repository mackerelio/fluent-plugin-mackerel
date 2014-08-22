require 'helper'

class MackerelOutputTest < Test::Unit::TestCase

  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    type mackerel
    api_key 123456
    hostid xyz
    metrics_name service.${out_key}
    out_keys val1,val2,val3
  ]

  CONFIG_NOHOST = %[
    type mackerel
    api_key 123456
    metrics_name service.${out_key}
    out_keys val1,val2,val3
  ]

  CONFIG_BLANK_METRICS = %[
    type mackerel
    api_key 123456
    metrics_prefix
    out_keys val1,val2,val3
  ]

  CONFIG_SMALL_FLUSH_INTERVAL = %[
    type mackerel
    api_key 123456
    hostid xyz
    metrics_name service.${out_key}
    out_keys val1,val2,val3
    flush_interval 1s
  ]

  CONFIG_ORIGIN = %[
    type mackerel
    api_key 123456
    hostid xyz
    metrics_name service.${out_key}
    out_keys val1,val2,val3
    origin example.domain
  ]

  def create_driver(conf = CONFIG, tag='test')
    Fluent::Test::BufferedOutputTestDriver.new(Fluent::MackerelOutput, tag).configure(conf)
  end

  def test_configure

    assert_raise(Fluent::ConfigError) {
      d = create_driver('')
    }

    assert_raise(Fluent::ConfigError) {
      d = create_driver(CONFIG_NOHOST)
    }

    assert_raise(Fluent::ConfigError) {
      d = create_driver(CONFIG_BLANK_METRICS)
    }

    d = create_driver(CONFIG_SMALL_FLUSH_INTERVAL)
    assert_equal d.instance.instance_variable_get(:@flush_interval), 60

    d = create_driver(CONFIG_ORIGIN)
    assert_equal d.instance.instance_variable_get(:@origin), 'example.domain'

    d = create_driver()
    assert_equal d.instance.instance_variable_get(:@api_key), '123456'
    assert_equal d.instance.instance_variable_get(:@hostid), 'xyz'
    assert_equal d.instance.instance_variable_get(:@metrics_name), 'service.${out_key}'
    assert_equal d.instance.instance_variable_get(:@out_keys), ['val1','val2','val3']
    assert_equal d.instance.instance_variable_get(:@flush_interval), 60
  end

  def test_write
    d = create_driver()
    mock(d.instance.mackerel).post_metrics([
      {"hostId"=>"xyz", "value"=>1.0, "time"=>1399997498, "name"=>"custom.service.val1"},
      {"hostId"=>"xyz", "value"=>2.0, "time"=>1399997498, "name"=>"custom.service.val2"},
      {"hostId"=>"xyz", "value"=>3.0, "time"=>1399997498, "name"=>"custom.service.val3"},
      {"hostId"=>"xyz", "value"=>5.0, "time"=>1399997498, "name"=>"custom.service.val1"},
      {"hostId"=>"xyz", "value"=>6.0, "time"=>1399997498, "name"=>"custom.service.val2"},
      {"hostId"=>"xyz", "value"=>7.0, "time"=>1399997498, "name"=>"custom.service.val3"},
      {"hostId"=>"xyz", "value"=>9.0, "time"=>1399997498, "name"=>"custom.service.val1"},
      {"hostId"=>"xyz", "value"=>10.0, "time"=>1399997498, "name"=>"custom.service.val2"},
    ])

    ENV["TZ"]="Asia/Tokyo"
    t = Time.strptime('2014-05-14 01:11:38', '%Y-%m-%d %T')
    d.emit({'val1' => 1, 'val2' => 2, 'val3' => 3, 'val4' => 4}, t)
    d.emit({'val1' => 5, 'val2' => 6, 'val3' => 7, 'val4' => 8}, t)
    d.emit({'val1' => 9, 'val2' => 10}, t)
    d.run()
  end

end

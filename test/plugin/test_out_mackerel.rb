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

  CONFIG_NO_OUT_KEYS = %[
    type mackerel
    api_key 123456
    hostid xyz
    metrics_name service.${out_key}
  ]

  CONFIG_OUT_KEY_PATTERN = %[
    type mackerel
    api_key 123456
    hostid xyz
    metrics_name service.${out_key}
    out_key_pattern ^val[0-9]$
  ]

  CONFIG_FOR_ISSUE_4 = %[
    type mackerel
    api_key 123456
    hostid xyz
    metrics_name a-${[1]}-b.${out_key}
    out_keys val1,val2
  ]

  CONFIG_BUFFER_LIMIT_DEFAULT = %[
    type mackerel
    service xyz
    api_key 123456
    out_keys val1,val2,val3
  ]

  CONFIG_BUFFER_LIMIT_IGNORE = %[
    type mackerel
    service xyz
    api_key 123456
    out_keys val1,val2,val3
    buffer_chunk_limit 1k
  ]

  CONFIG_SERVICE = %[
    type mackerel
    api_key 123456
    service xyz
    out_keys val1,val2
  ]

  CONFIG_SERVICE_REMOVE_PREFIX = %[
    type mackerel
    api_key 123456
    service xyz
    remove_prefix
    out_keys val1,val2
  ]

  CONFIG_INVALID_REMOVE_PREFIX = %[
    type mackerel
    api_key 123456
    remove_prefix
    out_keys val1,val2,val3
  ]

  CONFIG_SERVICE_USE_ZERO = %[
    type mackerel
    api_key 123456
    service xyz
    use_zero_for_empty
    out_keys val1,val2,val3
  ]

  def create_driver(conf = CONFIG)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::MackerelOutput).configure(conf)
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

    assert_raise(Fluent::ConfigError) {
      d = create_driver(CONFIG_NO_OUT_KEYS)
    }

    assert_raise(Fluent::ConfigError) {
      d = create_driver(CONFIG_INVALID_REMOVE_PREFIX)
    }

    assert_raise(Fluent::ConfigError) {
      d = create_driver(CONFIG_SMALL_FLUSH_INTERVAL)
    }

    d = create_driver(CONFIG_ORIGIN)
    assert_equal d.instance.instance_variable_get(:@origin), 'example.domain'

    d = create_driver()
    assert_equal d.instance.instance_variable_get(:@api_key), '123456'
    assert_equal d.instance.instance_variable_get(:@hostid), 'xyz'
    assert_equal d.instance.instance_variable_get(:@metrics_name), 'service.${out_key}'
    assert_equal d.instance.instance_variable_get(:@out_keys), ['val1','val2','val3']
    buffer = d.instance.instance_variable_get(:@buffer_config)
    assert_equal buffer.flush_interval, 60

    d = create_driver(CONFIG_OUT_KEY_PATTERN)
    assert_match d.instance.instance_variable_get(:@out_key_pattern), "val1"
    assert_no_match d.instance.instance_variable_get(:@out_key_pattern), "foo"

    d = create_driver(CONFIG_BUFFER_LIMIT_DEFAULT)
    assert_equal d.instance.instance_variable_get(:@buffer_chunk_limit), Fluent::Plugin::MackerelOutput::MAX_BUFFER_CHUNK_LIMIT
    assert_equal d.instance.instance_variable_get(:@buffer_queue_limit), 4096

    d = create_driver(CONFIG_BUFFER_LIMIT_IGNORE)
    assert_equal d.instance.instance_variable_get(:@buffer_chunk_limit), Fluent::Plugin::MackerelOutput::MAX_BUFFER_CHUNK_LIMIT

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
    t = Time.strptime('2014-05-14 01:11:38', '%Y-%m-%d %T').to_i
    d.run(default_tag: 'test') do
      d.feed(t, {'val1' => 1, 'val2' => 2, 'val3' => 3, 'val4' => 4})
      d.feed(t, {'val1' => 5, 'val2' => 6, 'val3' => 7, 'val4' => 8})
      d.feed(t, {'val1' => 9, 'val2' => 10})
    end
  end

  def test_write_pattern
    d = create_driver(CONFIG_OUT_KEY_PATTERN)
    mock(d.instance.mackerel).post_metrics([
      {"hostId"=>"xyz", "value"=>1.0, "time"=>1399997498, "name"=>"custom.service.val1"},
      {"hostId"=>"xyz", "value"=>2.0, "time"=>1399997498, "name"=>"custom.service.val2"},
    ])

    ENV["TZ"]="Asia/Tokyo"
    t = Time.strptime('2014-05-14 01:11:38', '%Y-%m-%d %T').to_i
    d.run(default_tag: 'test') do
      d.feed(t, {'val1' => 1, 'val2' => 2, 'foo' => 3})
    end
  end

  def test_write_issue4
    d = create_driver(CONFIG_FOR_ISSUE_4)
    mock(d.instance.mackerel).post_metrics([
      {"hostId"=>"xyz", "value"=>1.0, "time"=>1399997498, "name"=>"custom.a-status-b.val1"},
      {"hostId"=>"xyz", "value"=>2.0, "time"=>1399997498, "name"=>"custom.a-status-b.val2"},
    ])

    ENV["TZ"]="Asia/Tokyo"
    t = Time.strptime('2014-05-14 01:11:38', '%Y-%m-%d %T').to_i
    d.run(default_tag: 'test.status') do
      d.feed(t, {'val1' => 1, 'val2' => 2})
    end
  end

  def test_service
    d = create_driver(CONFIG_SERVICE)
    mock(d.instance.mackerel).post_service_metrics('xyz', [
      {"value"=>1.0, "time"=>1399997498, "name"=>"custom.val1"},
      {"value"=>2.0, "time"=>1399997498, "name"=>"custom.val2"},
    ])

    ENV["TZ"]="Asia/Tokyo"
    t = Time.strptime('2014-05-14 01:11:38', '%Y-%m-%d %T').to_i
    d.run(default_tag: 'test') do
      d.feed(t, {'val1' => 1, 'val2' => 2, 'foo' => 3})
    end
  end

  def test_service_remove_prefix
    d = create_driver(CONFIG_SERVICE_REMOVE_PREFIX)
    mock(d.instance.mackerel).post_service_metrics('xyz', [
      {"value"=>1.0, "time"=>1399997498, "name"=>"val1"},
      {"value"=>2.0, "time"=>1399997498, "name"=>"val2"},
    ])

    ENV["TZ"]="Asia/Tokyo"
    t = Time.strptime('2014-05-14 01:11:38', '%Y-%m-%d %T').to_i
    d.run(default_tag: 'test') do
      d.feed(t, {'val1' => 1, 'val2' => 2, 'foo' => 3})
    end
  end

  def test_service_use_zero
    d = create_driver(CONFIG_SERVICE_USE_ZERO)
    mock(d.instance.mackerel).post_service_metrics('xyz', [
      {"value"=>1.0, "time"=>1399997498, "name"=>"custom.val1"},
      {"value"=>2.0, "time"=>1399997498, "name"=>"custom.val2"},
      {"value"=>0.0, "time"=>1399997498, "name"=>"custom.val3"},
    ])

    ENV["TZ"]="Asia/Tokyo"
    t = Time.strptime('2014-05-14 01:11:38', '%Y-%m-%d %T').to_i
    d.run(default_tag: 'test') do
      d.feed(t, {'val1' => 1, 'val2' => 2, 'foo' => 3})
    end
  end

  def test_name_processor
    [
      {metrics_name: "${out_key}", expected: "val1"},
      {metrics_name: "name.${out_key}", expected: "name.val1"},
      {metrics_name: "a-${out_key}", expected: "a-val1"},
      {metrics_name: "${out_key}-b", expected: "val1-b"},
      {metrics_name: "a-${out_key}-b", expected: "a-val1-b"},
      {metrics_name: "name.a-${out_key}-b", expected: "name.a-val1-b"},
      {metrics_name: "${out_key}-a-${out_key}", expected: "val1-a-val1"},
      {metrics_name: "${out_keyx}", expected: "${out_keyx}"},
      {metrics_name: "${[1]}", expected: "status"},
      {metrics_name: "${[-1]}", expected: "status"},
      {metrics_name: "name.${[1]}", expected: "name.status"},
      {metrics_name: "a-${[1]}", expected: "a-status"},
      {metrics_name: "${[1]}-b", expected: "status-b"},
      {metrics_name: "a-${[1]}-b", expected: "a-status-b"},
      {metrics_name: "${[0]}.${[1]}", expected: "test.status"},
      {metrics_name: "${[0]}-${[1]}", expected: "test-status"},
      {metrics_name: "${[0]}-${[1]}-${out_key}", expected: "test-status-val1"},
      {metrics_name: "${[2]}", expected: ""},
    ].map { |obj|
      test_config = %[
        type mackerel
        api_key 123456
        hostid xyz
        metrics_name #{obj[:metrics_name]}
        out_keys val1,val2
      ]
      d = create_driver(test_config)
      name_processor = d.instance.instance_variable_get(:@name_processor)
      actual = name_processor.map{ |p| p.call(:out_key => 'val1', :tokens => ['test', 'status']) }.join('.')
      assert_equal obj[:expected], actual
    }
  end


end

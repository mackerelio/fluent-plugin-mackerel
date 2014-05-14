module Fluent
  class MackerelOutput < Fluent::BufferedOutput
    Fluent::Plugin.register_output('mackerel', self)

    # config_param :hoge, :string, :default => 'hoge'

    config_param :api_key, :string
    config_param :metrics_prefix, :string

    def initialize
      super
    end

    def configure(conf)
      super
    end

    def start
      super
    end

    def shutdown
      super
    end

    def format(tag, time, record)
      [tag, time, record].to_msgpack
    end

    def write(chunk)
      records = []
      chunk.msgpack_each do |(tag,time,record)|
      end
    end

  end
end
require 'mackerel/client'

module Fluent
  class MackerelOutput < Fluent::BufferedOutput
    Fluent::Plugin.register_output('mackerel', self)

    config_param :api_key, :string
    config_param :hostid, :string, :default => nil
    config_param :hostid_path, :string, :default => nil
    config_param :hostid_tag_regexp, :string, :default => nil
    config_param :metrics_prefix, :string
    config_param :out_keys, :string

    attr_reader :mackerel

    # Define `log` method for v0.10.42 or earlier
    unless method_defined?(:log)
      define_method("log") { $log }
    end

    def initialize
      super
    end

    def configure(conf)
      super

      @mackerel = Mackerel::Client.new(:mackerel_api_key => conf['api_key'])
      @out_keys = @out_keys.split(',')

      if @flush_interval < 60
        log.info("flush_interval less than 60s is not allowed and overwriteen to 60s")
        @flush_interval = 60
      end

      if @hostid.nil? and @hostid_path.nil? and @hostid_tag_regexp.nil?
        raise Fluent::ConfigError, "Either 'hostid' or 'hostid_path' or 'hostid_tag_regexp' must be specifed."
      end

      unless @hostid_path.nil?
        @hostid = File.open(@hostid_path).read
      end

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
      metrics = []
      chunk.msgpack_each do |(tag,time,record)|
        out_keys.map do |key|
          metrics << {
            'hostId' => @hostid || tag.match(@hostid_tag_regexp)[1],
            'value' => record[key].to_f,
            'time' => time,
            'name' => "%s.%s" % [@metrics_prefix, key]
          }
        end
      end

      begin
        @mackerel.post_metrics(metrics) unless metrics.empty?
      rescue => e
        log.error("out_mackerel:", :error_class => e.class, :error => e.message)
      end
      metrics.clear
    end
  end

end

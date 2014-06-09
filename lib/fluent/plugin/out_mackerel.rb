require 'mackerel/client'

module Fluent
  class MackerelOutput < Fluent::BufferedOutput
    Fluent::Plugin.register_output('mackerel', self)

    config_param :api_key, :string
    config_param :hostid, :string, :default => nil
    config_param :hostid_path, :string, :default => nil
    config_param :metrics_name, :string, :default => nil
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

      if @hostid.nil? and @hostid_path.nil?
        raise Fluent::ConfigError, "Either 'hostid' or 'hostid_path' must be specifed."
      end

      unless @hostid_path.nil?
        @hostid = File.open(@hostid_path).read
      end

      if matched = @hostid.match(/^\${tag_parts\[(\d+)\]}$/)
        idx = matched[1]
        @hostid_processor = Proc.new{ |args| args[:tokens][idx] }
      else
        @hostid_processor = Proc.new{ @hostid }
      end

      if @metrics_name
        @name_processor = @metrics_name.split('.').map{ |token|
          if token.start_with?('$')
            token = token[2..-2]
            if token == 'out_key'
              Proc.new{ |args| args[:out_key] }
            else
              idx = token.match(/\[(-?\d+)\]/)[1].to_i
              Proc.new{ |args| args[:tokens][idx] }
            end
          else
            Proc.new{ token }
          end
        }
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

        tokens = tag.split('.')
        out_keys.map do |key|
          name = @name_processor.nil? ? key :
            @name_processor.map{ |p| p.call(:out_key => key, :tokens => tokens) }.join('.')

          metrics << {
            'hostId' => @hostid_processor.call(:tokens => tokens),
            'value' => record[key].to_f,
            'time' => time,
            'name' => "%s.%s" % ['custom', name]
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

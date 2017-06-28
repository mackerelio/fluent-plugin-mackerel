require 'mackerel/client'

module Fluent::Plugin
  class MackerelOutput < Output
    Fluent::Plugin.register_output('mackerel', self)

    helpers :compat_parameters

    DEFAULT_FLUSH_INTERVAL = 60

    config_param :api_key, :string, :secret => true
    config_param :hostid, :string, :default => nil
    config_param :hostid_path, :string, :default => nil
    config_param :service, :string, :default => nil
    config_param :remove_prefix, :bool, :default => false
    config_param :metrics_name, :string, :default => nil
    config_param :out_keys, :string, :default => nil
    config_param :out_key_pattern, :string, :default => nil
    config_param :origin, :string, :default => nil
    config_param :use_zero_for_empty, :bool, :default => true

    MAX_BUFFER_CHUNK_LIMIT = 100 * 1024
    config_set_default :buffer_chunk_limit, MAX_BUFFER_CHUNK_LIMIT
    config_set_default :buffer_queue_limit, 4096
    config_section :buffer do
      config_set_default :@type, 'memory'
      config_set_default :flush_interval, DEFAULT_FLUSH_INTERVAL
    end

    attr_reader :mackerel

    # Define `log` method for v0.10.42 or earlier
    unless method_defined?(:log)
      define_method("log") { $log }
    end

    def initialize
      super
    end

    def configure(conf)
      compat_parameters_convert(conf, :buffer)
      super

      @mackerel = Mackerel::Client.new(:mackerel_api_key => conf['api_key'], :mackerel_origin => conf['origin'])

      if @out_keys
        @out_keys = @out_keys.split(',')
      end
      if @out_key_pattern
        @out_key_pattern = Regexp.new(@out_key_pattern)
      end
      if @out_keys.nil? and @out_key_pattern.nil?
        raise Fluent::ConfigError, "Either 'out_keys' or 'out_key_pattern' must be specifed."
      end

      if @buffer_config.flush_interval and @buffer_config.flush_interval < 60
        raise Fluent::ConfigError, "flush_interval less than 60s is not allowed."
      end

      unless @hostid_path.nil?
        @hostid = File.open(@hostid_path).read
      end

      if @hostid.nil? and @service.nil?
        raise Fluent::ConfigError, "Either 'hostid' or 'hostid_path' or 'service' must be specifed."
      end

      if @hostid and @service
        raise Fluent::ConfigError, "Niether 'hostid' and 'service' cannot be specifed."
      end

      if @remove_prefix and @service.nil?
        raise Fluent::ConfigError, "'remove_prefix' must be used with 'service'."
      end

      unless @hostid.nil?
        if matched = @hostid.match(/^\${tag_parts\[(\d+)\]}$/)
          hostid_idx = matched[1].to_i
          @hostid_processor = Proc.new{ |args| args[:tokens][hostid_idx] }
        else
          @hostid_processor = Proc.new{ @hostid }
        end
      end

      if @metrics_name
        @name_processor = @metrics_name.split('.').map{ |token|
          Proc.new{ |args|
            token.gsub(/\${(out_key|\[(-?\d+)\])}/) {
              if $1 == 'out_key'
                args[:out_key]
              else
                args[:tokens][$1[1..-1].to_i]
              end
            }
          }
        }
      end
    end

    def start
      super
    end

    def shutdown
      super
    end

    def formatted_to_msgpack_binary
      true
    end

    def format(tag, time, record)
      [tag, time, record].to_msgpack
    end

    def generate_metric(key, tokens, time, value)
      name = @name_processor.nil? ? key :
               @name_processor.map{ |p| p.call(:out_key => key, :tokens => tokens) }.join('.')

      metric = {
        'value' => value,
        'time' => time,
        'name' => @remove_prefix ? name : "%s.%s" % ['custom', name]
      }
      metric['hostId'] = @hostid_processor.call(:tokens => tokens) if @hostid
      return metric
    end

    def write(chunk)
      metrics = []
      processed = {}
      tags = {}
      time_latest = 0
      chunk.msgpack_each do |(tag,time,record)|
        tags[tag] = true
        tokens = tag.split('.')

        if @out_keys
          out_keys = @out_keys.select{|key| record.has_key?(key)}
        else # @out_key_pattern
          out_keys = record.keys.select{|key| @out_key_pattern.match(key)}
        end

        out_keys.map do |key|
          metrics << generate_metric(key, tokens, time, record[key].to_f)
          time_latest = time if time_latest == 0 || time_latest < time
          processed[tag + "." + key] = true
        end
      end

      if @out_keys && @use_zero_for_empty
        tags.each_key do |tag|
          tokens = tag.split('.')
          @out_keys.each do |key|
            unless processed[tag + "." + key]
              metrics << generate_metric(key, tokens, time_latest, 0.0)
            end
          end
        end
      end

      send(metrics) unless metrics.empty?
      metrics.clear
    end

    def send(metrics)
      log.debug("out_mackerel: #{metrics}")
      begin
        if @hostid
          @mackerel.post_metrics(metrics)
        else
          @mackerel.post_service_metrics(@service, metrics)
        end
      rescue => e
        log.error("out_mackerel:", :error_class => e.class, :error => e.message)
        raise e
      end
    end

  end

end

module Fluent

  class MackerelHostidTagOutput < Fluent::Output
    Fluent::Plugin.register_output('mackerel_hostid_tag', self)

    config_param :hostid_path, :string, :default => '/var/lib/mackerel-agent/id'
    config_param :add_to, :string
    config_param :key_name, :default => nil

    # Define `log` method for v0.10.42 or earlier
    unless method_defined?(:log)
      define_method("log") { $log }
    end

    def initialize
      super
    end

    def configure(conf)
      super
      @hostid = File.open(@hostid_path).read
      if @add_to == 'record' and @key_name.nil?
        raise Fluent::ConfigError, "'key_name' must be specified"
      end
    end

    def emit(tag, es, chain)
      if @add_to == 'tag_suffix'
        tag = [tag, @hostid].join('.')
      elsif @add_to == 'tag_prefix'
        tag = [@hostid, tag].join('.')
      end

      es.each do |time, record|
        if @add_to == 'record'
          record[@key_name] = @hostid
        end
        Fluent::Engine.emit(tag, time, record)
      end

      chain.next
    end

  end

end

module Fluent

  class MackerelHostidTagOutput < Fluent::Output
    Fluent::Plugin.register_output('mackerel_hostid_tag', self)

    config_param :hostid_path, :string, :default => '/var/lib/mackerel-agent/id'
    config_param :add_to, :string
    config_param :key_name, :default => nil
    config_param :add_prefix, :string, :default => nil
    config_param :remove_prefix, :string, :default => nil

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
      if @remove_prefix
        @removed_prefix_string = @remove_prefix + '.'
        @removed_length = @removed_prefix_string.length
      end
      @added_prefix_string = @add_prefix + '.' unless @add_prefix.nil?
    end

    def emit(tag, es, chain)
      if @remove_prefix and
          ( (tag.start_with?(@removed_prefix_string) and tag.length > @removed_length) or tag == @remove_prefix)
        tag = tag[@removed_length..-1]
      end
      if tag.length > 0
        tag = @added_prefix_string + tag if @added_prefix_string
      else
        tag = @add_prefix
      end
      if @add_to == 'tag'
        tag = [tag, @hostid].join('.')
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

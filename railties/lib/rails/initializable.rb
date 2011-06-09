module Rails
  module Initializable
    def self.included(base)
      base.extend ClassMethods
    end

    class Initializer
      attr_reader :name, :block

      def initialize(name, context, options, &block)
        @name, @context, @options, @block = name, context, options, block
      end

      def before
        @options[:before]
      end

      def after
        @options[:after]
      end

      def run(*args)
        @context.instance_exec(*args, &block)
      end

      def bind(context)
        return self if @context
        Initializer.new(@name, context, @options, &block)
      end
    end

    def run_initializers(*args)
      return if instance_variable_defined?(:@ran)
      initializers.each do |initializer|
        initializer.run(*args)
      end
      @ran = true
    end

    def initializers
      @initializers ||= self.class.initializers_for(self)
    end

    module ClassMethods
      def initializers
        @initializers ||= []
      end

      def initializers_chain
        initializers = []
        ancestors.reverse_each do |klass|
          next unless klass.respond_to?(:initializers)
          initializers = initializers + klass.initializers
        end
        initializers
      end

      def initializers_for(binding)
        initializers_chain.map { |i| i.bind(binding) }
      end

      def initializer(name, opts = {}, &blk)
        raise ArgumentError, "A block must be passed when defining an initializer" unless blk
        opts[:after] ||= initializers.last.name unless initializers.empty? || initializers.find { |i| i.name == opts[:before] }
        initializers << Initializer.new(name, nil, opts, &blk)
      end
    end
  end
end

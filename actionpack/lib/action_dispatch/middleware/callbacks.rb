module ActionDispatch
  class Callbacks
    include ActiveSupport::NewCallbacks

    define_callbacks :call, :terminator => "result == false", :scope => :kind
    define_callbacks :prepare, :scope => :name

    # Add a preparation callback. Preparation callbacks are run before every
    # request in development mode, and before the first request in production mode.
    #
    # If a symbol with a block is given, the symbol is used as an identifier.
    # That allows to_prepare to be called again with the same identifier to
    # replace the existing callback. Passing an identifier is a suggested
    # practice if the code adding a preparation block may be reloaded.
    def self.to_prepare(*args, &block)
      if args.first.is_a?(Symbol) && block_given?
        define_method :"__#{args.first}", &block
        set_callback(:prepare, :"__#{args.first}")
      else
        set_callback(:prepare, *args, &block)
      end
    end

    def self.before(*args, &block)
      set_callback(:call, :before, *args, &block)
    end

    def self.around(*args, &block)
      set_callback(:call, :around, *args, &block)
    end

    def self.after(*args, &block)
      set_callback(:call, :after, *args, &block)
    end

    class << self
      # DEPRECATED
      alias_method :before_dispatch, :before
      alias_method :around_dispatch, :around
      alias_method :after_dispatch, :after
    end

    def initialize(app, prepare_each_request = false)
      @app, @prepare_each_request = app, prepare_each_request
      _run_prepare_callbacks
    end

    def call(env)
      _run_call_callbacks do
        _run_prepare_callbacks if @prepare_each_request
        @app.call(env)
      end
    end
  end
end
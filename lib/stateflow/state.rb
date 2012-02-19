module Stateflow
  class State
    attr_accessor :name, :options
    
    def initialize(name, &options)
      @name = name
      @options = Hash.new
      
      instance_eval(&options) if block_given?
    end
    
    def enter(method = nil, &block)
      (@options[:enter] ||= []) << (method.nil? ? block : method)
    end
    
    def exit(method = nil, &block)
      (@options[:exit] ||= []) << (method.nil? ? block : method)
    end
    
    def execute_action(action, base)
      (@options[action.to_sym] || []).each do |cb|
        case cb
        when Symbol, String
          base.send(cb)
        when Proc
          cb.call(base)
        end
      end
    end
  end
end
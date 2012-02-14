module Stateflow
  class Machine
    attr_accessor :states, :initial_state, :events
    
    def initialize(&machine)
      @states, @events = Hash.new, Hash.new
      instance_eval(&machine)
    end
    
    def state_column(name = :state)
      @state_column ||= name
    end

    private    
    def initial(name)
      @initial_state_name = name
    end
    
    def state(*names, &options)
      names.each do |name|
        unless @states[name.to_sym]
          state = Stateflow::State.new(name, &options)
          @initial_state = state if @states.empty? || @initial_state_name == name
          @states[name.to_sym] = state
        else
          @states[name.to_sym].instance_eval(&options) if block_given?
        end
      end
    end
    
    def event(name, &transitions)
      unless @events[name.to_sym]
        @events[name.to_sym] = Stateflow::Event.new(name, &transitions)
      else
        @events[name.to_sym].instance_eval(&transitions)
      end
    end
  end
end

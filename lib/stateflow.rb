module Stateflow
  def self.included(base)
    base.send :include, InstanceMethods
    base.extend ClassMethods
    Stateflow::Persistence.set(base)
  end
  
  def self.persistence
    @@persistence ||= :active_record
  end
  
  def self.persistence=(persistence)
    @@persistence = persistence
  end
  
  module ClassMethods
    attr_reader :machine
    
    def stateflow(&block)
      unless machine
        @machine = Stateflow::Machine.new(&block)
      else
        @machine.instance_eval(&block)
      end
      
      @machine.states.values.each do |state|
        state_name = state.name
        define_method "#{state_name}?" do
          state_name == current_state.name
        end
      end
      
      @machine.events.keys.each do |key|
        define_method "#{key}" do
          fire_event(key, :save => false)
        end
        
        define_method "#{key}!" do
          fire_event(key, :save => true)
        end
      end
    end

    def machine
      if @machine
        @machine
      elsif superclass.respond_to?(:machine)
        @machine = superclass.machine.dup
      end
    end
  end
  
  module InstanceMethods
    attr_accessor :_previous_state
    
    def current_state  
      @current_state ||= load_from_persistence.nil? ? machine.initial_state : machine.states[load_from_persistence.to_sym]
    end
    
    def set_current_state(new_state, options = {})
      save_to_persistence(new_state.name.to_s, options)
      @current_state = new_state
    end
    
    def machine
      self.class.machine
    end
    
    private
    def fire_event(event_name, options = {})
      event = machine.events[event_name.to_sym]
      raise Stateflow::NoEventFound.new("No event matches #{event_name}") if event.nil?
      event.fire(current_state, self, options)
    end
  end
  
  autoload :Machine, 'stateflow/machine'
  autoload :State, 'stateflow/state'
  autoload :Event, 'stateflow/event'
  autoload :Transition, 'stateflow/transition'
  autoload :Persistence, 'stateflow/persistence'
  autoload :Exception, 'stateflow/exception'
end

# source CC-3 : https://stackoverflow.com/a/47997380
module Interface
  def method(name)
    define_method(name) { |*args|
      raise "interface method #{name} not implemented"
    }
  end

  def required_variable(name)
    define_method(name) do
      sub_class_var = instance_variable_get("@#{name}")
      throw "@#{name} must be defined" unless sub_class_var
      sub_class_var
    end
  end

  def optional_variable(name, default)
    define_method(name) do
      instance_variable_get("@#{name}") || default
    end
  end
end

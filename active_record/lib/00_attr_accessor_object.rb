class AttrAccessorObject
  def self.my_attr_accessor(*names)
    names.each do |name|
      instance_name = "@#{name.to_s}".to_sym
      setter_name = "#{name}=".to_sym

      define_method(name) do
        instance_variable_get(instance_name)
      end

      define_method(setter_name) do |new_val|
        instance_variable_set(instance_name, new_val)
      end

    end
  end
end

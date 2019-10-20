$PRIMITIVES = ['byte', 'short', 'int', 'long', 'string', 'array', 'boolean']

module Primitives
  def Primitives.is_number?(type)
    type == "byte" || type == "short" || type == "int" || type == "long" || type == "boolean"
  end
  def Primitives.is_array?(type)
    type == "array"
  end
  def Primitives.size_of(type)
    case type
    when "byte"
      1
    when "short"
      2
    when "int"
      4
    when "long"
      8
    when "boolean"
      1
    else
      0
    end
  end
end

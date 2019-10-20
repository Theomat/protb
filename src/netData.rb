# Imports ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
require_relative 'primitives.rb'
# Class ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
class NetData
  attr_reader :name
  attr_reader :type
  attr_reader :subtype
  attr_reader :length
  attr_reader :after
  attr_writer :after
  attr_reader :mask
  attr_writer :mask
  attr_reader :shift
  attr_writer :shift
  attr_reader :consume
  attr_writer :consume
  attr_reader :super_type
  attr_writer :super_type
  def initialize(hash)
    @name = hash['name']
    @type = hash['type']
    @subtype = hash['subtype']
    @is_packable = hash['packable'] == nil || hash['packable'] == false
    @after = hash['after']
    @length = hash['length']
    @mask = hash['mask']
    @shift = hash['shift']
    @consume = hash['consume'] == nil || hash['consume']
    case @type
      when "boolean"
        @length = 1
      when "string"
        if @after == nil and @length.is_a? String
          @after = @length
        end
      when nil
        @type = "byte"
        if @length > 8
          if @length > 16
            if @length > 32
              @type = "long"
            else
              @type = "int"
            end
          else
            @type = "short"
          end
        end
    end
    if Primitives.is_number?(@type) and @length.is_a? Integer and @mask == "auto"
      @mask = (1 << @length) - 1
    end
    @super_type = @type
  end
  def check_valid(supported_types)
    if not (supported_types.include? @type)
      return "data #{@name} has unsupported type #{@type}"
    end
    if Primitives.is_array?(@type) and (not supported_types.include? @subtype)
      return "data #{@name} has unsupported subtype #{@subtype}"
    elsif Primitives.is_number?(@type) and @length != nil
      if Primitives.size_of(@type) * 8 < @length
        return "data #{@name} has length superior to type length"
      elsif @length <= 0
        return "data #{@name} has negative or null length"
      end
    end
    return nil
  end
  def can_be_packed?
    @is_packable and ((Primitives.is_number?(@type) and @length and @length < 8 * Primitives.size_of(@type)) or type == "boolean")
  end
  def to_s
    "netData(name=#{@name}, type=#{@type})"
  end
end

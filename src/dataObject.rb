# Imports ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
require_relative "netData.rb"
require_relative "primitives.rb"
# Class ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
class DataObject
  attr_reader :name
  attr_reader :data
  attr_reader :path
  attr_reader :is_packet
  attr_reader :packetID
  attr_writer :packetID
  attr_reader :fixed_size
  def initialize(hash, relPath)
    @name = hash["name"]
    @data = hash["data"].map { |e| NetData.new e }
    @is_packet = hash["object"] == nil || hash["object"] == false
    @packetID = nil
    @path = relPath
    @fixed_size = 0
  end
  def check_types (supported_types)
    errors = @data.map { |e| e.check_valid(supported_types) }.select{|e| e != nil }
    if errors.length > 0
      return "#{@name}: \n#{errors.join("\n  ")}"
    end
    return nil
  end
  def each_data_in_order
    @data.each { |e| yield e }
  end
  def has_fixed_size? (fixed_size_types)
    @data.map { |e| fixed_size_types.include?(e.type) }.reduce(&:&)
  end
  def unpacked_size(fixed_size_types, objects)
    @data.map{ |el|
      if objects[el.type]
        objects[el.type].unpacked_size(fixed_size_types, objects)
      else
        Primitives.size_of(el.type)
      end
    }.reduce(&:+)
  end
  def packed_size(fixed_size_types, objects)
    temp = @data.select { |e| e.consume and fixed_size_types.include?(e.type) }
    @fixed_size = temp.map{ |el|
      if objects[el.type]
        objects[el.type].unpacked_size(fixed_size_types, objects)
      else
        Primitives.size_of(el.type)
      end }.reduce(&:+)
    return @fixed_size
  end
  def pack
    # Data packing -------------------------------------------------------------
    packables = data.select { |e| e.can_be_packed? and e.after == nil }
    packed = []
    tries = {}
    ["byte", "short", "int", "long"].each { |type|
      size = Primitives.size_of(type) * 8
      tries = Hash.new()
      packables.select{|e| e.length < size }.sort_by { |e| - e.length }.each{ |el|
        r = size - el.length
        if tries[r]
          others = tries[r]
          tries.delete(r)
          others.push(el)
          others.each{|x| x.super_type = type }
          packed.push(others)
        else
          added = false
          for i in 1..(r-1) do
            if tries[i]
              added = true
              others = tries[i]
              tries.delete(i)
              others.push(el)
              tries[i + el.length] = others
              break
            end
          end
          if not added
            tries[el.length] = [el]
          end
        end
      }
      packables = []
      tries.each_value { |list| packables |= list }
    }
    # Try to pack the remaining interestingly
    tries.each_value{|list|
      if list.length > 1
        total_length = list.map { |e| e.length }.reduce(&:+)
        super_type = "byte"
        if total_length > 8
          if total_length > 16
            if total_length > 32
              super_type = "long"
            else
              super_type = "int"
            end
          else
            super_type = "short"
          end
        end
        list.each { |e| e.super_type = super_type }
        packed.push(list)
      end
    }
    # Now pack them together
    packed.each {|list|
      shift = Primitives.size_of(list[0].super_type) * 8
      list.each { |el|
        shift -= el.length
        el.consume = false
        el.shift = shift
        el.mask = (1 << el.length) - 1
      }
      list[list.length() - 1].consume = true
    }
    # Size computation ---------------------------------------------------------
    @fixed_size = @data.select{ |el| el.consume }.map{ |el| Primitives.size_of(el.super_type) }.reduce(&:+)
    # Ordering -----------------------------------------------------------------
    afters = {"none"=> [], nil=>[]}
    remaining = @data
    last = "none"
    added = 1

    while added > 0 and not remaining.empty?
      not_added = []
      added = 0
      remaining.each { |netData|
        if afters[netData.after]
          temp = afters[netData.after]
          temp.push netData
          afters.delete(netData.after)
          afters[netData.name] = temp
          added += 1
        else
          not_added.push netData
        end
      }
      if not afters[nil]
        afters[nil] = []
      end
      remaining = not_added
    end
    if added == 0
      return true, "#{@name} unsatisfiable order dependency"
    end
    ordered = []
    afters.each_value { |list|
      ordered |= list
    }
    @data = ordered
    return false, nil
  end
  def to_s
    "dataObject(name=#{@name}, data:#{@data})"
  end
end

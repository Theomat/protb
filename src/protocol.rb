module Protocol
  @objects = {}
  @fixed_sizes = ["byte", "short", "int", "long", "boolean"]
  @packets = []
  def Protocol.add (parsedData)
    if parsedData.is_packet
      @packets.push parsedData
    else
      @objects[parsedData.name] = parsedData
    end
  end
  def Protocol.describe
    "#{@packets.length} packet(s) and #{@objects.size} object(s)"
  end
  def Protocol.check_types
    supported_types = $PRIMITIVES | @objects.keys
    (@packets | @objects.values()).each { |e|
      error = e.check_types(supported_types)
      if error
        return error
      end
    }
    return nil
  end
  def Protocol.export (generator, srcFolder, dstFolder, writeGlue)
    @packets.each { |packet|
      generator.writePacketCode(packet, srcFolder, dstFolder)
    }
    @objects.each_value { |object|
      generator.writeDataObjectCode(object, srcFolder, dstFolder)
    }
    generator.writeGlueReaderCode(@packets, dstFolder) if writeGlue
  end
  def Protocol.pack ()
    # Set the packets with their ID and pack the objects
    @packets.each_with_index { |packet, packetID|
      packet.packetID = packetID
      error, message = packet.pack()
      if error
        return true, message
      end
    }
    @objects.each_value { |object|
      error, message = object.pack()
      if error
        return true, message
      end
    }
    # Determine objects with fixed size ----------------------------------------
    added = 1
    remaining = @packets | @objects.values()
    while added > 0
      added = 0
      not_added = []
      remaining.each{ |object|
        if object.has_fixed_size?(@fixed_sizes)
          @fixed_sizes.push(object.name)
          object.packed_size(@fixed_sizes, @objects)
          added += 1
        else
          not_added.push(object)
        end
      }
      remaining = not_added
    end
    return false, nil
  end
  def Protocol.sizes ()
    packed_size = 0
    unpacked_size = 0
    (@packets | @objects.values()).each { |object|
      packed_size += object.fixed_size || 0
      unpacked_size += object.unpacked_size(@fixed_sizes, @objects) || 0
    }
    return packed_size, unpacked_size
  end
end

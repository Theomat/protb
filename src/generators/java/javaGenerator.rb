# Imports ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
require 'fileutils'
require_relative "../../generator.rb"
require_relative "../../primitives.rb"
require_relative "../generatorUtils.rb"
# Module Globals +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
def is_number
  Proc.new{ |type| Primitives.is_number? type }
end
# Utils ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
def toJavaFile (originPath, srcFolder, dstFolder, prefix)
  filename = "#{prefix}#{GeneratorUtils.to_camelcase(File.basename(originPath, ".json"))}"
  folder, relative = GeneratorUtils.dst_folder_relative_to_src(originPath, srcFolder, dstFolder)
  FileUtils.mkpath(folder)
  path = File.join(folder, "#{filename}.java")
  file = File.open(path, 'w')
  package = relative.gsub("/", ".")
  return file, package, filename
end
def flatTypeToRealObject (type)
  case type
  when "byte"
    "byte"
  when "short"
    "short"
  when "int"
    "int"
  when "long"
    "long"
  when "boolean"
    "boolean"
  else
    type.capitalize
  end
end
def typeToRealObject (el)
  if el.type == "array"
    "ArrayList<#{flatTypeToRealObject(el.subtype)}>"
  else
    flatTypeToRealObject(el.type)
  end
end
def visibilityToKeyword (visibility)
  case visibility
  when "public"
    "public "
  when "private"
    "private "
  else
    ""
  end
end
# Writer code generation +++++++++++++++++++++++++++++++++++++++++++++++++++++++
def writeWriteCode (el, file, indent)
  case el.type
  when is_number
    writtenValue = el.name
    if el.type == "boolean"
      writtenValue = "(#{el.name} ? 1 : 0)"
    end
    writtenValue = "(#{el.name} & #{el.mask})" if el.mask
    writtenValue = "#{el.name} << #{el.shift}" if el.shift
    file.write("#{indent}offset = DataWriter.write#{el.super_type.capitalize}(array, offset, #{writtenValue}, #{el.consume});\n")
  when "array"
    file.write("#{indent}DataWriter.writeInt(array, offset, #{el.name}.size());\n")
    file.write("#{indent}offset += 4;\n")
    file.write("#{indent}for(int index = 0; index < #{el.name}.size(); index++){\n")
    writeWriteCode(NetData.new({"name" => "#{el.name}.get(index)", "type" => el.subtype}), file, indent + "  ")
    file.write("#{indent}}\n")
  when 'string'
    if el.length
      file.write("#{indent}DataWriter.writeString(array, offset, #{el.name}, #{el.length}, ' ');\n")
      file.write("#{indent}offset += #{el.length};\n")
    else
      file.write("#{indent}DataWriter.writeCString(array, offset, #{el.name});\n")
      file.write("#{indent}offset += #{el.name}.length() + 1;\n")
    end
  else
    file.write("#{indent}offset = #{el.name}.write(array, offset);\n")
  end
end
# Parser code generation +++++++++++++++++++++++++++++++++++++++++++++++++++++++
def assignment_setter
  Proc.new {|var, value| "#{var} = #{value}"}
end
def array_setter
  Proc.new {|var, value| "#{var}.add(#{value})"}
end
def writeParseCode (el, file, indent, setter = assignment_setter)
  case el.type
  when is_number
    readingCode = "DataReader.read#{el.super_type.capitalize}(array, offset)"
    readingCode = "(#{readingCode} >> #{el.shift})" if el.shift
    readingCode = "(#{readingCode} & #{el.mask})" if el.mask
    if el.type == "boolean"
      readingCode = "(#{readingCode} != 0)"
    end
    file.write("#{indent}#{setter.call(el.name, readingCode)};\n")
    file.write("#{indent}offset += #{Primitives.size_of(el.super_type)};\n") if el.consume
  when "array"
    file.write("#{indent}int array_length_#{el.name} = DataReader.readInt(array, offset);\n")
    file.write("#{indent}offset += 4;\n")
    file.write("#{indent}#{el.name}.clear();\n")
    file.write("#{indent}for(int index = 0; index < array_length_#{el.name}; index++){\n")
    writeParseCode(NetData.new({"name" => "#{el.name}[index]", "type" => el.subtype}), file, indent + "  ", array_setter)
    file.write("#{indent}}\n")
  when 'string'
    if el.length
      file.write("#{indent}#{setter.call(el.name, "DataReader.readString(array, offset, #{el.length})")};\n")
      file.write("#{indent}offset += #{el.length};\n")
    else
      file.write("#{indent}#{setter.call(el.name, "DataReader.readCString(array, offset)")};\n")
      file.write("#{indent}offset += #{el.name}.length() + 1;\n")
    end
  else
    file.write("#{indent}offset = #{el.name}.read(array, offset);\n")
  end
end
# Parser code generation +++++++++++++++++++++++++++++++++++++++++++++++++++++++
def writeSizeCode (el, file, indent)
  case el.type
  when is_number
    return
  when "array"
    file.write("#{indent} for(int index = 0; index < #{el.name}.length; index++){\n")
    writeSizeCode(NetData.new({"name" => "#{el.name}[index]", "type" => el.subtype}), file, indent + "  ")
    file.write("#{indent}}\n")
  when 'string'
    if el.length
      file.write("#{indent}size += #{el.length};\n")
    else
      file.write("#{indent}size += #{el.name}.length() + 1;\n")
    end
  else
    file.write("#{indent}size += #{el.name}.size();\n")
  end
end
# Bloat code generation ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
def writeBloat(file, package, className, name, visibility)
  file.write("package #{package};\n\n") if package != "."
  file.write("// This code has been generated by #{$NAME} version #{$VERSION} using #{name}.\n")
  file.write("// This class is merely a data container.\n")
  file.write("#{visibilityToKeyword(visibility)} final class #{className} implements DataObject {\n\n")
end
# Variables code generation ++++++++++++++++++++++++++++++++++++++++++++++++++++
def writeVariableDeclarationCode (object, visibility, file, indent, objectPrefix)
  vis_keyword = visibilityToKeyword(visibility)
  object.each_data_in_order{ |el|
    if $PRIMITIVES.include?(el.type)
      file.write("#{indent}#{vis_keyword}#{typeToRealObject(el)} #{el.name}")
      if Primitives.is_array?(el.type)
        file.write(" = new #{typeToRealObject(el)}()")
      end
    else
      file.write("#{indent}#{vis_keyword}#{objectPrefix}#{typeToRealObject(el)} #{el.name}")
      file.write(" = new #{objectPrefix}#{typeToRealObject(el)}()")
    end
    file.write(";\n")
  }
  file.write("\n")
end
# Class ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
class JavaGenerator
  include Generator
  attr_reader:name
  attr_reader:description
  attr_reader:language
  attr_reader:options
  attr_reader:version
  def initialize()
    @name = "Java Exporter"
    @language = "Java"
    @version = "0.0.1"
    @description = "Export your code to java with read, write, and size methods."
    @options = {
      "package" => "",
      "object.prefix" => "Data",
      "packet.prefix" => "Packet",
      "attributes.visibility" => "default",
      "class.visibility" => "public"
    }
  end
  def writeDataObjectCode (dataObject, srcFolder, dstFolder)
    file, add_package, filename = toJavaFile(dataObject.path, srcFolder, dstFolder, @options["object.prefix"])
    package = @options["package"]
    if package.length > 0
      package += '.'
    end
    package += add_package
    writeBloat(file, package, filename, @name, @options["class.visibility"])

    writeVariableDeclarationCode(dataObject, @options["attributes.visibility"], file, "  ", @options["object.prefix"])
    # Parse method -------------------------------------------------------------
    file.write("  public final int read(byte[] array, int offset){\n")
    dataObject.each_data_in_order{ |el| writeParseCode(el, file, "    ") }
    file.write("    return offset;\n")
    file.write("  }\n\n")
    # Size method --------------------------------------------------------------
    file.write("  public final int size(){\n")
    file.write("    int size = #{dataObject.fixed_size};\n")
    dataObject.each_data_in_order{ |el| writeSizeCode(el, file, "    ") }
    file.write("    return size;\n")
    file.write("  }\n\n")
    # Write method -------------------------------------------------------------
    file.write("  public final int write(byte[] array, int offset){\n")
    dataObject.each_data_in_order{ |el| writeWriteCode(el, file, "    ") }
    file.write("    return offset;\n")
    file.write("  }\n\n")

    file.write("}\n")
  end
  def writePacketCode (packet, srcFolder, dstFolder)
    file, add_package, filename = toJavaFile(packet.path, srcFolder, dstFolder, @options["packet.prefix"])
    package = @options["package"]
    if package.length > 0
      package += '.'
    end
    package += add_package
    writeBloat(file, package, filename, @name, @options["class.visibility"])
    file.write("  public static final int packetID = #{packet.packetID};\n")
    writeVariableDeclarationCode(packet, @options["attributes.visibility"], file, "  ", @options["object.prefix"])
    # Parse method -------------------------------------------------------------
    file.write("  public final int read(byte[] array, int offset){\n")
    packet.each_data_in_order{ |el| writeParseCode(el, file, "    ") }
    file.write("    return offset;\n")
    file.write("  }\n\n")
    # Size method --------------------------------------------------------------
    file.write("  public final int size(){\n")
    file.write("    int size = #{packet.fixed_size};\n")
    packet.each_data_in_order{ |el| writeSizeCode(el, file, "    ") }
    file.write("    return size;\n")
    file.write("  }\n\n")
    # Write method -------------------------------------------------------------
    file.write("  public final int write(byte[] array, int offset){\n")
    file.write("    DataWriter.writeInt(array, offset, packetID);\n")
    file.write("    offset += 4;\n")
    packet.each_data_in_order{ |el| writeWriteCode(el, file, "    ") }
    file.write("    return offset;\n")
    file.write("  }\n")

    file.write("}\n")
  end
  def writeGlueReaderCode (packets, dstFolder)
    # Packet Reader ------------------------------------------------------------
    file, package, filename = toJavaFile("./packetReader.json", ".", dstFolder, "")
    file.write("// This code has been generated by #{$NAME} version #{$VERSION} using #{@name}.\n")
    file.write("public final class #{filename} {\n")
    file.write("  private #{filename}(){}\n\n")
    file.write("  public static Packet read(byte[] array, int offset){\n")
    file.write("    int packetID = DataReader.readInt(array, offset);\n")
    file.write("    Packet packet;\n")
    file.write("    switch(packetID){\n")
    packets.each { |packet|
      file.write("      case #{packet.packetID}:\n")
      file.write("        packet = new #{@options["packet.prefix"]}#{GeneratorUtils.to_camelcase(packet.name)}();\n")
      file.write("        break;\n")
    }
    file.write("      default:\n")
    file.write("        throw new Exception(\"Unknown packet with id \" + packetID);\n")
    file.write("        break;\n")
    file.write("    }\n")
    file.write("    int new_offset = packet.read(array, offset + 4);\n")
    file.write("    return packet;\n")
    file.write("  }\n")
    file.write("}")
    # Copy pasta
    ["DataReader", "DataWriter", "DataObject"].each{ |filename|
      dst, useless1, useless2 = toJavaFile("./#{filename}.json", ".", dstFolder, "")
      FileUtils.cp(GeneratorUtils.relative_path_to_script("./java/#{filename}.java"), dst)
    }
  end
  def configure (options)
    options.each_key { |key|
      @options[key] = options[key]
    }
  end
end
# Addition to the list of generators +++++++++++++++++++++++++++++++++++++++++++
$generators.push JavaGenerator.new

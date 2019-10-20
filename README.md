# Protocol Builder

```version: 0.0.1```

This tool allows you to easily generate code to write and read packets.

Supported languages :
  - Java

## Features

- Packet read, write code generation
- Glue code generation for automated parsing
- Enable packing of loose bits length variables into better bits length variables to save data
- Packing supports automatic bit mask and bit shift
- Support primitives : array, byte, short, int, long, boolean, string
- Allow data ordering or free ordering depending on your needs

## Usage

Display the help to get a good start.
```bash
protb -h
```

Or if you have cloned this repository you can try with one of the examples in verbose mode :
```bash
./src/protb -f ./examples/old_maid -v -l java
```


## List of generators

| Name | Language | Version | Link |
|:----:|:--------:|:-------:|:----:|
| Java Exporter | Java | ```0.0.1``` | ```src/generators/java``` |

## Write your own generator

Just implement the same class model as ```src/genrators/java/javaGenerator.rb```. It should look like this :
```ruby
class MyGenerator
  include Generator
  attr_reader:name
  attr_reader:description
  attr_reader:language
  attr_reader:options
  attr_reader:version
  def initialize()
    @name = "MyGenerator"
    @language = "Java"
    @version = "0.0.1"
    @description = "Export your code to java with MyGenerator."
    @options = {
      "package" => "",
      "object.prefix" => "Data",
      "packet.prefix" => "Packet",
      "attributes.visibility" => "default",
      "class.visibility" => "public"
    }
    # Any options that you may provide with the --options in the command line should have a default value
  end
  def writeDataObjectCode (dataObject, srcFolder, dstFolder)
    # write the code for the given dataObject
    # srcFolder is the root of the input folder
    # dstFolder is the root of the output folder
  end
  def writePacketCode (packet, srcFolder, dstFolder)
    # write the code for the given dataObject
    # assert dataObject.is_packet
    # this is a packet and can be handled differently
    # srcFolder is the root of the input folder
    # dstFolder is the root of the output folder
  end
  def writeGlueReaderCode (packets, dstFolder)
    # packets is the list of packets
    # dstFolder is the root of the output folder
    # write some glue code, like a method that takes a byte array and gives out the parsed packet
    # bear in mind that if the user use the --no-glue option this method won't be called
  end
  def configure (options)
    # called before anything else
    # options is a hash with the user specified options given with the argument --options
  end
end
```

Don't forget at the end of your file to add the following line in order to be detected by ```protb```.
```ruby
$generators.push MyGenerator.new
```

# Imports ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
require_relative 'interface.rb'
# Module +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
module Generator
  extend Interface
  # name type string should be readable
  required_variable(:name)
  required_variable(:version)
  # language type string should be readable and match one of LANGUAGES
  required_variable(:language)

  optional_variable(:description, "")
  optional_variable(:options, {})

  method(:configure)
  method(:writeDataObjectCode)
  method(:writePacketCode)
  method(:writeGlueReaderCode)

end

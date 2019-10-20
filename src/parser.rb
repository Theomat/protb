# Imports ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
require 'json'
require_relative 'dataObject.rb'
# Methods ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
def check_data data
  variables = []
  # Check all variables are named and they have a type
  data.each { |element|
    name = element["name"]
    if name == nil then
      return "data has no name"
    elsif element["type"] == nil and not element['length'].is_a? Integer
      return "data #{name} has nil type"
    else
      if variables.include? name
        return "data #{name} is already defined"
      else
        variables.push(name)
      end
    end
  }
  return nil
end
# Module +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
module Parser
  @error = nil
  def Parser.parseJSONFile (path)
    @error = nil
    file = File.open path
    data = JSON.parse file.read
    if data["name"] == nil
      @error = "#{path} has no attribute 'name'"
      return nil
    end
    @error = check_data data["data"]
    if @error
      @error = "#{path}: #{@error}"
      return nil
    end
    return DataObject.new(data, path)
  end
  def Parser.error
    if @error
      return "error parsing #{@error}"
    else
      return nil
    end
  end
end

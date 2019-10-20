# Imports ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
require 'pathname'
# Module +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
module GeneratorUtils
  def GeneratorUtils.relative_path(origin, file)
    Pathname.new(file).relative_path_from(Pathname.new(origin)).to_s
  end
  def GeneratorUtils.dst_folder_relative_to_src(file, src, dst)
    relative = GeneratorUtils.relative_path(src, File.dirname(file))
    return File.join(dst, relative), relative
  end
  def GeneratorUtils.to_camelcase(str)
    str.gsub(/[_]/, " ").gsub(/\b\w/, &:upcase).gsub(/\s/, "")
  end
  def GeneratorUtils.indent(str, indentation)
    str.gsub(/^/, indentation)
  end
  def GeneratorUtils.relative_path_to_script(file)
    File.join(File.dirname(__FILE__), file)
  end
end

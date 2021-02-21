require 'shellwords'

class Grapher
  def self.run(txt:, dot:, png:)
    lyrics = IO.read(txt)
    words = lyrics.upcase.split(/[^[[:word:]]']+/).map{|w| "\"#{w}\""}
    IO.write(dot, "digraph G {\n" + words.join(' -> ') + "\n}")
    `dot -Tpng -Nshape=box #{Shellwords.shellescape(dot)} -o #{Shellwords.shellescape(png)}`
    $?.success? or raise "dot failed for #{dot}"
    puts "Created #{png}"
  end
end

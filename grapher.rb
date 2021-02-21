require 'shellwords'

class Grapher

  def self.run(txt:, dot:, png:)
    grapher = new(txt: txt)
    grapher.run
    grapher.save(dot: dot, png: png)
  end

  def initialize(
    txt:,
    remove_duplicate_edges: false,
    upcase: true
  )
    @txt = txt
    @remove_duplicate_edges = remove_duplicate_edges
    @upcase = upcase
  end

  def run
    lyrics = IO.read(@txt).split(/[^[[:word:]]']+/)

    @nodes = {}
    @edges = []

    previous_word_id = nil
    lyrics.each do |word|
      word_id = word.downcase.gsub("'", "_")

      @nodes[word_id] ||= {
        label: (@upcase ? word.upcase : word),
      }

      if previous_word_id
        @edges << {from: previous_word_id, to: word_id}
      end

      previous_word_id = word_id
    end

    @edges.uniq! if @remove_duplicate_edges
  end

  def save(dot:, png:)
    File.open(dot, "w") do |f|
      f.puts "digraph {"

      @nodes.each_entry do |node_id, node_def|
        f.puts "  #{node_id} #{attrs(node_def)}"
      end

      @edges.each do |edge|
        f.puts "  #{edge[:from]} -> #{edge[:to]} #{attrs(edge[:attrs])}"
      end

      f.puts "}"
    end

    `dot -Tpng -Nshape=box #{Shellwords.shellescape(dot)} -o #{Shellwords.shellescape(png)}`
    $?.success? or raise "dot failed for #{dot}"

    puts "Created #{png}"
  end

  private

  def attrs(hash)
    return if !hash || hash.empty?

    pairs = hash.each_entry.map do |k, v|
      "#{k}=#{v.inspect}"
    end

    "[#{pairs.join(", ")}]"
  end

end

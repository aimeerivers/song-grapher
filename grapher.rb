require 'shellwords'

class Grapher

  def self.run(txt:, dot:, png:)
    grapher = new(txt: txt)
    grapher.run
    grapher.save(dot: dot, png: png)
  end

  def initialize(
    txt:,
    remove_duplicate_edges: true,
    remove_redundant_edges: true,
    upcase: true
  )
    @txt = txt
    @remove_duplicate_edges = remove_duplicate_edges
    @remove_redundant_edges = remove_redundant_edges
    @upcase = upcase
  end

  def run
    lyrics = IO.read(@txt).split(/[^[[:word:]]']+/)

    @nodes = {}
    @edges = []

    previous_word_id = nil
    lyrics.each do |word|
      word_id = node_id_for([word])

      @nodes[word_id] ||= {
        words: [word],
        attrs: {
          label: (@upcase ? word.upcase : word),
        },
      }

      if previous_word_id
        @edges << {from: previous_word_id, to: word_id}
      end

      previous_word_id = word_id
    end

    @edges.uniq! if @remove_duplicate_edges
    remove_redundant_edges if @remove_redundant_edges
  end

  def save(dot:, png:)
    File.open(dot, "w") do |f|
      f.puts "digraph {"

      @nodes.each_entry do |node_id, node_def|
        f.puts "  #{node_id} #{attrs(node_def[:attrs])}"
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

  def node_id_for(words)
    words.map(&:downcase).join("__").gsub("'", "_")
  end

  def remove_redundant_edges
    # Simplify "A->B" to "AB", if:
    # - A's only output is B, and B's only input is A
    # and the combined "AB" node doesn't yet exist

    node_in_count = @edges.map { |e| e[:to] }.group_by(&:itself).transform_values(&:length)
    node_out_count = @edges.map { |e| e[:from] }.group_by(&:itself).transform_values(&:length)

    loop do
      removed_any = false

      @edges.each_with_index do |e, edge_index|
        from = e[:from]
        to = e[:to]
        next unless node_out_count[from] == 1 && node_in_count[to] == 1

        next if from == to # Damn it, Daft Punk!

        combined_node_id = node_id_for(
          @nodes[from][:words] + @nodes[to][:words]
        )
        next if @nodes.key?(combined_node_id)

        puts "Combine #{from} + #{to} -> #{combined_node_id}"
        words = @nodes[from][:words] + @nodes[to][:words]

        @nodes[combined_node_id] = {
            words: words,
            attrs: {
                label: (@upcase ? words.join(" ").upcase : words.join(" ")),
            },
        }

        # Update any edges to A, to refer to AB
        # Update any edges from B, to refer to AB
        @edges.each { |other_edge| other_edge[:to] = combined_node_id if other_edge[:to] == from }
        @edges.each { |other_edge| other_edge[:from] = combined_node_id if other_edge[:from] == to }

        # Remove the edge
        @edges.slice!(edge_index, 1)

        # Remove nodes A and B
        @nodes.delete(from)
        @nodes.delete(to)

        node_in_count[combined_node_id] = node_in_count[from]
        node_out_count[combined_node_id] = node_out_count[to]
        node_in_count.delete(from)
        node_in_count.delete(to)

        removed_any = true
        break
      end

      break unless removed_any
    end
  end

  def attrs(hash)
    return if !hash || hash.empty?

    pairs = hash.each_entry.map do |k, v|
      "#{k}=#{v.inspect}"
    end

    "[#{pairs.join(", ")}]"
  end

end

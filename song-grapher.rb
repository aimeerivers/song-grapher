
lyrics = IO.read('song.txt')
words = lyrics.upcase.split(/[^[[:word:]]']+/).map{|w| "\"#{w}\""}
IO.write('song.dot', "digraph G {\n" + words.join(' -> ') + "\n}")
`dot -Tpng -Nshape=box song.dot -o song.png`

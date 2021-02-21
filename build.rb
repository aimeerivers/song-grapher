require 'find'
require_relative './grapher'

Find.find('songs') do |file|
  if file.end_with?('.txt')
    dot_file = file.sub(".txt", ".dot")
    png_file = file.sub(".txt", ".png")
    Grapher.run(txt: file, dot: dot_file, png: png_file)
  end
end

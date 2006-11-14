all: parser.rb

clean:
	rm -f parser.rb

parser.rb: parser.y
	racc -v -o parser.rb parser.y

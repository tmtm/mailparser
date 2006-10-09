all: parser.rb

clean:
	rm -rf parser.rb

parser.rb: parser.y
	racc -v -o parser.rb parser.y

DEST = mailparser/rfc2822/parser.rb mailparser/rfc2045/parser.rb mailparser/rfc2183/parser.rb

%.rb: %.y
	racc -v -o $@ $<

all: $(DEST)

clean:
	rm -f $(DEST)

test: test_

test_:
	ruby -I . -w test.rb

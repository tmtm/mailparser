DEST = lib/mailparser/rfc2822/parser.rb lib/mailparser/rfc2045/parser.rb lib/mailparser/rfc2183/parser.rb
TRASH = $(DEST:.rb=.output)

%.rb: %.y
	racc -v -o $@ $<

all: $(DEST)
	ruby ./setup.rb config
	ruby ./setup.rb setup

install:
	ruby ./setup.rb install

clean:
	rm -f $(DEST) $(TRASH)

test: test_

test_:
	ruby -I ./lib -w test.rb

all:
	cd mailparser/rfc2822 && make
	cd mailparser/rfc2045 && make
	cd mailparser/rfc2183 && make

clean:
	cd mailparser/rfc2822 && make clean
	cd mailparser/rfc2045 && make clean
	cd mailparser/rfc2183 && make clean

test: test_

test_:
	ruby -I . -w test.rb

all:
	cd rfc2822 && make
	cd rfc2045 && make
	cd rfc2183 && make

clean:
	cd rfc2822 && make clean
	cd rfc2045 && make clean
	cd rfc2183 && make clean

test: test_

test_:
	ruby -w test.rb

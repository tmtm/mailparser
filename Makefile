all:
	cd rfc2822; make
	cd rfc2822obs; make
	cd rfc2045; make
	cd rfc2183; make

clean:
	cd rfc2822; make clean
	cd rfc2822obs; make clean
	cd rfc2045; make clean
	cd rfc2183; make clean

test:
	ruby -w test_rfc2822.rb
	ruby -w test_rfc2822obs.rb
	ruby -w test_rfc2045.rb
	ruby -w test_rfc2183.rb

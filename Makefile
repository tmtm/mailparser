all:
	cd rfc2822; make
	cd rfc2822obs; make

clean:
	cd rfc2822; make clean
	cd rfc2822obs; make clean

test:
	ruby -w test_rfc2822.rb
	ruby -w test_rfc2822obs.rb

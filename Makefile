test.so : test.c
	g++ -g -Wall --shared -fPIC -o $@ -llua5.2 $^
clean : 
	rm test.so

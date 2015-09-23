luashadow.so : sample.c
	g++ -g -Wall --shared -fPIC -o $@ -llua5.2 $^
clean : 
	rm luashadow.so

#include <iostream>

using namespace std;

class ClassA
{
public:
	ClassA(int a) : a_(a) {}
	ClassA() : a_(0) {}
	void sayhi() {cout << "What the fuck !? " << a_ << endl;}
	void sayhi(int a) {cout << "What the fuck !? " << a << endl;}
	void sayhi(int a, int b) {cout << "What the fuck !? " << a << " " << b << endl;}

private:
	int a_;
};

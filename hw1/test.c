#include <stdio.h>

extern void hw_sprintf();

int main() {
	char buf[10];
	hw_sprintf();
	printf("%s", "hello");
	return 0;
}

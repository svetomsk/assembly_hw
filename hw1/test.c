#include <stdio.h>

extern void hw_sprintf(char* out, char* const format, ...);
extern void itoa(char * buf, int value, int flags);

int main() {
	char buf[100];
	itoa(buf, 123, 0);
	printf("%s", buf);
	return 0;
}

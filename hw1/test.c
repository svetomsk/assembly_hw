#include <stdio.h>

extern void hw_sprintf(char* out, char* const format, ...);

int main() {
	char buf[100];
	hw_sprintf(buf, "% +++i %---++i", 4294967295, 123);
	printf("%s", buf);
	return 0;
}

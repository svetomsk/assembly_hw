#include <stdio.h>
#include <string.h>

extern void hw_sprintf(char* out, char* const format, ...);
extern void itoa(char * buf, int value, int flags, ...);

static int args[5];
static int SIGN = 1 << 0;
static int SPACE = 1 << 1;
static int ALIGN = 1 << 2;
static int ZERO = 1 << 3;
static int WIDTH = 1 << 4;

static int correct = 1;

void red(char * s) {
	printf("\033[1;31m%s\033[0m\n", s);
}

void green(char * s) {
	printf("\033[1;32m%s\033[0m\n", s);
}

void blue(char * s) {
	printf("\033[1;34m%s\033[0m\n", s);
}

void black(char * s) {
	printf("%s\n", s);
}

int cmp(char * a, char * b, int length) {
	int i = 0;
	while(b[i] != 0) {
		if(a[i] != b[i]) {
			return 0;
		}
		i++;
	}
	return 1;
}

void test_itoa(int value, int flags, int width, char * args) {
	char buf[100];
	itoa(buf, value, flags, width);
	char buf1[100];
	sprintf(buf1, args, value);
	buf[strlen(buf1)] = 0;
	printf("\"%s\" vs ", buf);
	printf("\"%s\" ", buf1);
	if(cmp(buf, buf1, width) == 1) {
		green("OK");
	} else {
		correct = 0;
		red("FAIL");
	}
	printf("----\n");
}

void test_sprintf(int value, char * args) {
	char buf[100];
	sprintf(buf, args, value);
	buf[strlen(buf)] = 0;
	printf("\"%s\" vs ", buf);
	char buf1[100];
	sprintf(buf1, args, value);
	printf("\"%s\" ", buf1);
	if(cmp(buf, buf1, strlen(buf1)) == 1) {
		green("OK");
	} else {
		correct = 0;
		red("FAIL");
	}
	printf("----\n");
}

void num_to_str(char buf[], int flags) {

	strcpy(buf, "");
	if(flags & SIGN) {
		strcat(buf, "SIGN ");
	}
	if(flags & ZERO) {
		strcat(buf, " ZERO ");
	}
	if(flags & ALIGN) {
		strcat(buf, " ALIGN ");
	}
	if(flags & WIDTH) {
		strcat(buf, " WIDTH ");
	}
	if(flags & SPACE) {
		strcat(buf, " SPACE ");
	}
}

void construct_string(int flags, char s[], int width) {
	int cnt = 0;
	s[0] = '%';

	if(flags & SIGN) {
		cnt++;
		s[cnt] = '+';
	}
	if(flags & SPACE) {
		cnt++;
		s[cnt] = ' ';
	}
	if(flags & ZERO) {
		cnt++;
		s[cnt] = '0';
	}
	if(flags & ALIGN) {
		cnt++;
		s[cnt] = '-';
	}
	if(flags & WIDTH) {
		if(width > 9) {
			cnt++;
			s[cnt] = '0' + (width/10);
		}
		cnt++;
		s[cnt] = '0' + width%10;
	}
	cnt++;
	s[cnt] = 'i';
	cnt++;
	s[cnt] = 0;
}

void rec_test_itoa(int flags, int cur, int depth, int max_depth) {
	if(depth == max_depth) {
		char buf[100];
		num_to_str(buf, flags);
		blue(buf);
		int width = 4;
		if(flags & WIDTH) {
			width = 10;
		}

		construct_string(flags, buf, width);
		test_itoa(1234, flags, width, buf);
		test_itoa(-4567, flags, width, buf);
		return;
	}
	for(int i = cur + 1; i < 5; i++) {
		if(((flags & ZERO) && i == 2) || ((flags & ALIGN) && i == 3)) {
			continue;
		}
		rec_test_itoa(flags | args[i], i, depth + 1, max_depth);
	}
}

void rec_test_sprintf(int flags, int cur, int depth, int max_depth) {
	if(depth == max_depth) {
		char buf[100];
		num_to_str(buf, flags);
		blue(buf);
		int width = 4;
		if(flags & WIDTH) {
			width = 10;
		}

		construct_string(flags, buf, width);
		test_sprintf(1234, buf);
		test_sprintf(-4567, buf);
	}
	for(int i = cur + 1; i < 5; i++) {
		rec_test_sprintf(flags | args[i], i, depth + 1, max_depth);
	}
}

void do_itoa_testing() {
	blue("SINGLE FLAG TESTS");
	rec_test_itoa(0, -1, 0, 1);

	blue("TWO FLAGS TESTS");
	rec_test_itoa(0, -1, 0, 2);

	blue("THREE FLAGS TESTS");
	rec_test_itoa(0, -1, 0, 3);

	blue("FOUR FLAGS TESTS");
	rec_test_itoa(0, -1, 0, 4);
}

void do_sprintf_testing() {
	blue("SIGNLE FLAG TEST");
	rec_test_sprintf(0, -1, 0, 1);

	blue("TWO FLAGS TESTS");
	rec_test_sprintf(0, -1, 0, 2);

	blue("THREE FLAGS TESTS");
	rec_test_sprintf(0, -1, 0, 3);

	blue("FOUR FLAGS TESTS");
	rec_test_sprintf(0, -1, 0, 4);

}

int main() {
	args[0] = SIGN;
	args[1] = SPACE;
	args[2] = ALIGN;
	args[3] = ZERO;
	args[4] = WIDTH;

	// do_itoa_testing();
	// do_sprintf_testing();

	// if(correct) {
	// 	green("TEST PASSED");
	// } else {
	// 	red("TEST FAILED");
	// }

	// char buf[100];
	// itoa(buf, 1234, ZERO | WIDTH | SPACE, 10);
	// buf[10] = 0;
	// printf("%s\n", buf);
	return 0;
}

#include <stdio.h>

extern char **environ;
int main(int argc, char *argv[])
{
  char **p;
  int count = 0;
  for (p = environ; *p != NULL; p++)
  { /* перебор всех элементов массива */
    count += 1;
    printf("%s\n", *p); 
    if (count == 9)
     { 
	break;
     }
  }
}

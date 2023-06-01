#include <stdio.h>

extern char **environ;
int main(int argc, char *argv[])
{
  char **p;
  int count_env = 0;
  for (p = environ; *p != NULL; p++) /* перебор всех элементов массива */
    count_env += 1;
  printf("%d\n", count_env); 
  printf("%d\n", argc);
}


#include <stdio.h>
#include <unistd.h>

int main(void)
{
  int status;
  for (int i = 0; i < 10; ++i)
  {
    int pid = fork();
    if (pid == 0)
	{
	  printf("Child process\n");
	  sleep(5);
	  return 0;
	}
    else
	{
	  printf("Parent process\n");
	}
  }
  while (wait(&status) > 0)
  {
    sleep(0.1);
  }  

  return 0;
}

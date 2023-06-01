#include <stdio.h>
#include <unistd.h>

int main(void)
{
  int pid = fork();
  
  if (pid == 0) {
    printf("Это сообщение из дочернего процесса\n");
    printf("PID %d PPID %d\n", getpid(), getppid());
  } else if (pid > 0) {
    printf("Это сообщение из родительского процесса.\n"
           "Идентификатор дочернего процесса:  %d\n", pid);
  }

  return 0;
}

#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <termios.h>
#include <unistd.h>

int main() {
  struct termios oldt, newt;
  int tty_fd = open("/dev/tty", O_RDONLY);
  if (tty_fd == -1)
    return 1;

  // Set raw mode on tty
  if (tcgetattr(tty_fd, &oldt) == -1)
    return 1;
  newt = oldt;
  newt.c_lflag &= ~(ICANON | ECHO);
  if (tcsetattr(tty_fd, TCSANOW, &newt) == -1)
    return 1;

  unsigned char buffer[8];
  ssize_t n;

  // Read loop from tty_fd
  while ((n = read(tty_fd, buffer, sizeof(buffer))) > 0) {
    // Output as hex to stdout
    for (ssize_t i = 0; i < n; i++) {
      printf("%02x", buffer[i]);
    }
    printf("\n");
    fflush(stdout);

    // Ctrl+Q (0x11) to exit driver safely
    if (n == 1 && buffer[0] == 0x11)
      break;
  }

  // Restore mode
  tcsetattr(tty_fd, TCSANOW, &oldt);
  close(tty_fd);
  return 0;
}

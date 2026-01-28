// TUI native C stub for terminal I/O
// Provides raw mode, terminal size, and non-blocking I/O

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <termios.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <errno.h>

// Store original terminal settings for restoration
static struct termios orig_termios;
static int raw_mode_enabled = 0;

// File descriptor for keyboard input (STDIN_FILENO or /dev/tty)
static int tty_fd = -1;
static int tty_fd_opened = 0; // 1 if we opened /dev/tty ourselves

// File descriptor for TUI output (STDOUT_FILENO or /dev/tty)
static int tty_out_fd = -1;
static int tty_out_fd_opened = 0; // 1 if we opened /dev/tty ourselves for output

// Get the file descriptor for keyboard input
// Falls back to /dev/tty if stdin is not a tty (e.g., when used in a pipe)
static int get_tty_fd(void) {
    if (tty_fd >= 0) return tty_fd;

    if (isatty(STDIN_FILENO)) {
        tty_fd = STDIN_FILENO;
        tty_fd_opened = 0;
    } else {
        // stdin is not a tty (piped input), try /dev/tty
        tty_fd = open("/dev/tty", O_RDONLY);
        if (tty_fd >= 0) {
            tty_fd_opened = 1;
        }
    }
    return tty_fd;
}

// Get the file descriptor for TUI output
// Falls back to /dev/tty if stdout is not a tty (e.g., when output is captured)
static int get_tty_out_fd(void) {
    if (tty_out_fd >= 0) return tty_out_fd;

    if (isatty(STDOUT_FILENO)) {
        tty_out_fd = STDOUT_FILENO;
        tty_out_fd_opened = 0;
    } else {
        // stdout is not a tty (output captured), use /dev/tty for UI
        tty_out_fd = open("/dev/tty", O_WRONLY);
        if (tty_out_fd >= 0) {
            tty_out_fd_opened = 1;
        }
    }
    return tty_out_fd;
}

// Enable raw mode for character-by-character input
// Uses TCSADRAIN instead of TCSAFLUSH to preserve pending input
int tui_enable_raw_mode(void) {
    if (raw_mode_enabled) return 0;

    int fd = get_tty_fd();
    if (fd < 0) return -1;

    if (tcgetattr(fd, &orig_termios) == -1) return -1;

    struct termios raw = orig_termios;
    // Input: no break, no CR to NL, no parity check, no strip, no flow control
    raw.c_iflag &= ~(BRKINT | ICRNL | INPCK | ISTRIP | IXON);
    // Output: disable post processing
    raw.c_oflag &= ~(OPOST);
    // Control: set 8 bit chars
    raw.c_cflag |= (CS8);
    // Local: no echo, no canonical, no extended, no signal chars
    raw.c_lflag &= ~(ECHO | ICANON | IEXTEN | ISIG);
    // Return each byte, no timeout
    raw.c_cc[VMIN] = 0;
    raw.c_cc[VTIME] = 1; // 100ms timeout

    if (tcsetattr(fd, TCSADRAIN, &raw) == -1) return -1;

    raw_mode_enabled = 1;
    return 0;
}

// Disable raw mode and restore original settings
// Uses TCSADRAIN instead of TCSAFLUSH to preserve pending input
int tui_disable_raw_mode(void) {
    if (!raw_mode_enabled) return 0;

    int fd = get_tty_fd();
    if (fd < 0) return 0;

    if (tcsetattr(fd, TCSADRAIN, &orig_termios) == -1) return -1;

    // Close /dev/tty if we opened it for input
    if (tty_fd_opened && tty_fd >= 0) {
        close(tty_fd);
        tty_fd = -1;
        tty_fd_opened = 0;
    }

    // Close /dev/tty if we opened it for output
    if (tty_out_fd_opened && tty_out_fd >= 0) {
        close(tty_out_fd);
        tty_out_fd = -1;
        tty_out_fd_opened = 0;
    }

    raw_mode_enabled = 0;
    return 0;
}

// Check if raw mode is enabled
int tui_is_raw_mode(void) {
    return raw_mode_enabled;
}

// Get terminal size (columns, rows)
int tui_get_terminal_cols(void) {
    struct winsize ws;
    if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == -1 || ws.ws_col == 0) {
        return 80; // default
    }
    return ws.ws_col;
}

int tui_get_terminal_rows(void) {
    struct winsize ws;
    if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == -1 || ws.ws_row == 0) {
        return 24; // default
    }
    return ws.ws_row;
}

// Read a single byte from tty (non-blocking in raw mode)
// Returns -1 if no data available, or the byte value (0-255)
int tui_read_byte(void) {
    int fd = get_tty_fd();
    if (fd < 0) return -1;

    unsigned char c;
    ssize_t n = read(fd, &c, 1);
    if (n <= 0) return -1;
    return (int)c;
}

// Read up to max_len bytes into buffer
// Returns number of bytes read, or -1 on error
int tui_read_bytes(unsigned char* buf, int max_len) {
    int fd = get_tty_fd();
    if (fd < 0) return -1;

    ssize_t n = read(fd, buf, max_len);
    if (n < 0) return -1;
    return (int)n;
}

// Write string to tty (uses /dev/tty when stdout is captured)
void tui_print_raw(const char* str, int len) {
    int fd = get_tty_out_fd();
    if (fd >= 0) {
        write(fd, str, len);
    }
}

// Write bytes to tty (uses /dev/tty when stdout is captured)
void tui_write_bytes(const unsigned char* buf, int len) {
    int fd = get_tty_out_fd();
    if (fd >= 0) {
        write(fd, buf, len);
    }
}

// Flush tty output
void tui_flush(void) {
    int fd = get_tty_out_fd();
    if (fd >= 0 && fd != STDOUT_FILENO) {
        // For /dev/tty, use fsync since we use write() not fwrite()
        fsync(fd);
    } else {
        fflush(stdout);
    }
}

// Write string to stdout directly (always stdout, never /dev/tty)
// Used for final output like shell scripts and selection results
void tui_print_stdout(const char* str, int len) {
    write(STDOUT_FILENO, str, len);
    fflush(stdout);
}

// Check if a TTY is available for input (stdin or /dev/tty)
int tui_is_tty(void) {
    if (isatty(STDIN_FILENO)) return 1;
    // Check if /dev/tty is available
    int fd = open("/dev/tty", O_RDONLY);
    if (fd >= 0) {
        close(fd);
        return 1;
    }
    return 0;
}

// Check if stdin specifically is a TTY (for detecting pipe input)
// Returns 1 if stdin is a TTY (no pipe), 0 if stdin is piped
int tui_stdin_is_tty(void) {
    return isatty(STDIN_FILENO) ? 1 : 0;
}

// Sleep for milliseconds
void tui_sleep_ms(int ms) {
    usleep(ms * 1000);
}

// Append a line to a file (for history)
// Creates file if it doesn't exist
// Returns 0 on success, -1 on error
int tui_append_to_file(const char* path, int path_len, const char* content, int content_len) {
    // Null-terminate the path (create a copy)
    char* path_str = malloc(path_len + 1);
    if (!path_str) return -1;
    memcpy(path_str, path, path_len);
    path_str[path_len] = '\0';

    FILE* f = fopen(path_str, "a");
    free(path_str);
    if (!f) return -1;

    fwrite(content, 1, content_len, f);
    fwrite("\n", 1, 1, f);
    fclose(f);
    return 0;
}

// Read entire file contents (for history)
// Returns allocated buffer (caller must free) or NULL on error
// Sets *out_len to the length of the content
char* tui_read_file(const char* path, int path_len, int* out_len) {
    *out_len = 0;

    // Null-terminate the path
    char* path_str = malloc(path_len + 1);
    if (!path_str) return NULL;
    memcpy(path_str, path, path_len);
    path_str[path_len] = '\0';

    FILE* f = fopen(path_str, "r");
    free(path_str);
    if (!f) return NULL;

    // Get file size
    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fseek(f, 0, SEEK_SET);

    if (size <= 0) {
        fclose(f);
        return NULL;
    }

    char* buf = malloc(size + 1);
    if (!buf) {
        fclose(f);
        return NULL;
    }

    size_t read_size = fread(buf, 1, size, f);
    fclose(f);

    buf[read_size] = '\0';
    *out_len = (int)read_size;
    return buf;
}

// Write entire file contents (for history, overwrites)
int tui_write_file(const char* path, int path_len, const char* content, int content_len) {
    char* path_str = malloc(path_len + 1);
    if (!path_str) return -1;
    memcpy(path_str, path, path_len);
    path_str[path_len] = '\0';

    FILE* f = fopen(path_str, "w");
    free(path_str);
    if (!f) return -1;

    fwrite(content, 1, content_len, f);
    fclose(f);
    return 0;
}

// Execute shell command and capture stdout+stderr into provided buffer
// Returns number of bytes written to out_buf, or -1 on error
int tui_exec_command(const char* cmd, int cmd_len, char* out_buf, int out_buf_len) {
    // Null-terminate the command and append stderr redirect
    // Format: "cmd 2>&1" to capture both stdout and stderr
    char* cmd_str = malloc(cmd_len + 6); // +6 for " 2>&1\0"
    if (!cmd_str) return -1;
    memcpy(cmd_str, cmd, cmd_len);
    memcpy(cmd_str + cmd_len, " 2>&1", 6); // includes null terminator

    FILE* fp = popen(cmd_str, "r");
    free(cmd_str);
    if (!fp) return -1;

    // Read output directly into provided buffer
    size_t total_len = 0;
    size_t remaining = out_buf_len - 1; // Leave room for null terminator

    while (remaining > 0) {
        size_t n = fread(out_buf + total_len, 1, remaining, fp);
        if (n == 0) break;
        total_len += n;
        remaining -= n;
    }

    pclose(fp);
    out_buf[total_len] = '\0';
    return (int)total_len;
}

// Get current time in milliseconds (monotonic, relative to first call)
#include <time.h>

static int64_t start_time_ms = -1;

int tui_get_time_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    int64_t now_ms = (int64_t)ts.tv_sec * 1000 + ts.tv_nsec / 1000000;
    if (start_time_ms < 0) {
        start_time_ms = now_ms;
    }
    return (int)(now_ms - start_time_ms);
}

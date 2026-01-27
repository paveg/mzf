/**
 * tui_helper.c - Native terminal I/O helpers for mzf
 *
 * Provides C implementations for mizchi/tui extern functions
 * for the native MoonBit target.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <termios.h>
#include <sys/ioctl.h>
#include <sys/time.h>
#include <time.h>
#include <fcntl.h>
#include <errno.h>

// Store original terminal settings
static struct termios orig_termios;
static int raw_mode_enabled = 0;

/**
 * Enable raw mode for terminal input
 */
int tui_enable_raw_mode(void) {
    if (raw_mode_enabled) return 0;

    if (tcgetattr(STDIN_FILENO, &orig_termios) == -1) {
        return -1;
    }

    struct termios raw = orig_termios;
    // Input: no break, no CR to NL, no parity check, no strip, no flow control
    raw.c_iflag &= ~(BRKINT | ICRNL | INPCK | ISTRIP | IXON);
    // Output: disable post processing
    raw.c_oflag &= ~(OPOST);
    // Control: set 8 bit chars
    raw.c_cflag |= (CS8);
    // Local: no echo, no canonical, no extended, no signal chars
    raw.c_lflag &= ~(ECHO | ICANON | IEXTEN | ISIG);
    // Read with timeout
    raw.c_cc[VMIN] = 0;
    raw.c_cc[VTIME] = 1;  // 100ms timeout

    if (tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw) == -1) {
        return -1;
    }

    raw_mode_enabled = 1;
    return 0;
}

/**
 * Disable raw mode, restore original terminal settings
 */
int tui_disable_raw_mode(void) {
    if (!raw_mode_enabled) return 0;

    if (tcsetattr(STDIN_FILENO, TCSAFLUSH, &orig_termios) == -1) {
        return -1;
    }

    raw_mode_enabled = 0;
    return 0;
}

/**
 * Check if raw mode is enabled
 */
int tui_is_raw_mode(void) {
    return raw_mode_enabled;
}

/**
 * Get terminal width (columns)
 */
int tui_get_terminal_cols(void) {
    struct winsize ws;
    if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == -1 || ws.ws_col == 0) {
        return 80;  // Default fallback
    }
    return ws.ws_col;
}

/**
 * Get terminal height (rows)
 */
int tui_get_terminal_rows(void) {
    struct winsize ws;
    if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == -1 || ws.ws_row == 0) {
        return 24;  // Default fallback
    }
    return ws.ws_row;
}

/**
 * Read a single byte from stdin
 * Returns the byte value (0-255) or -1 on error/no input
 */
int tui_read_byte(void) {
    unsigned char c;
    ssize_t n = read(STDIN_FILENO, &c, 1);
    if (n <= 0) {
        return -1;
    }
    return (int)c;
}

/**
 * Write bytes to stdout
 */
void tui_write_bytes(const unsigned char* buf, int len) {
    write(STDOUT_FILENO, buf, len);
}

/**
 * Flush stdout
 */
void tui_flush(void) {
    fflush(stdout);
}

/**
 * Check if stdin is a TTY
 */
int tui_is_tty(void) {
    return isatty(STDIN_FILENO);
}

/**
 * Sleep for specified milliseconds
 */
void tui_sleep_ms(int ms) {
    struct timespec ts;
    ts.tv_sec = ms / 1000;
    ts.tv_nsec = (ms % 1000) * 1000000;
    nanosleep(&ts, NULL);
}

/**
 * Get current time in milliseconds (since epoch)
 */
int tui_get_time_ms(void) {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    // Return lower 32 bits to fit in int
    return (int)((tv.tv_sec * 1000 + tv.tv_usec / 1000) & 0x7FFFFFFF);
}

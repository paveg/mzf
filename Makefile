.PHONY: all build-js build-native test clean fmt check

# Output directories
BUILD_DIR := _build
NATIVE_DIR := $(BUILD_DIR)/native/release/build
JS_DIR := $(BUILD_DIR)/js/release/build

# TUI native C source
TUI_NATIVE_C := .mooncakes/mizchi/tui/io/tui_native.c
TUI_NATIVE_O := $(BUILD_DIR)/tui_native.o

all: build-js build-native

# Build JS/WASM target
build-js:
	moon build --target js

# Build native target (requires manual linking due to moon bug with extern "C")
build-native: $(TUI_NATIVE_O)
	@# moon build will fail at link stage due to missing tui symbols, but generates .c files
	@rm -f $(NATIVE_DIR)/main/main.exe
	@moon build --target native >/dev/null 2>&1 || true
	@echo "Linking native binary with tui_native.o..."
	@/usr/bin/cc -o $(NATIVE_DIR)/main/main.exe \
		-I$$HOME/.moon/include -fwrapv -fno-strict-aliasing -O2 \
		$$HOME/.moon/lib/libmoonbitrun.o \
		$(NATIVE_DIR)/main/main.c \
		$(NATIVE_DIR)/runtime.o \
		$(NATIVE_DIR)/.mooncakes/moonbitlang/async/internal/c_buffer/libc_buffer.a \
		$(NATIVE_DIR)/.mooncakes/moonbitlang/async/internal/os_string/libos_string.a \
		$(NATIVE_DIR)/.mooncakes/moonbitlang/async/os_error/libos_error.a \
		$(NATIVE_DIR)/.mooncakes/moonbitlang/async/internal/fd_util/libfd_util.a \
		$(NATIVE_DIR)/.mooncakes/moonbitlang/async/internal/time/libtime.a \
		$(NATIVE_DIR)/.mooncakes/moonbitlang/async/internal/event_loop/libevent_loop.a \
		$(TUI_NATIVE_O) \
		-lm

# Compile TUI native C helper
$(TUI_NATIVE_O): $(TUI_NATIVE_C)
	@mkdir -p $(BUILD_DIR)
	cc -c -o $@ $<

# Run tests (JS target required due to extern "C" limitation in wasm-gc)
test:
	moon test --target js

# Format code
fmt:
	moon fmt

# Type check
check:
	moon check

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR)
	moon clean

# Install binary to ~/.local/bin
install: build-native
	@mkdir -p ~/.local/bin
	cp $(NATIVE_DIR)/main/main.exe ~/.local/bin/mzf
	@echo "Installed mzf to ~/.local/bin/mzf"

# Show binary sizes
size: build-js build-native
	@echo "=== Binary Sizes ==="
	@ls -lh $(NATIVE_DIR)/main/main.exe 2>/dev/null | awk '{print "Native: " $$5}'
	@ls -lh $(JS_DIR)/main/main.js 2>/dev/null | awk '{print "JS:     " $$5}'

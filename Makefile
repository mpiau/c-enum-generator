# Makefile useful reminder
# Based from https://stackoverflow.com/questions/3220277/what-do-the-makefile-symbols-and-mean :
# -------------------------------------------------------------------------------------------
# There are seven “core” automatic variables:
# $@: The filename representing the target.
# $%: The filename element of an archive member specification.
# $<: The filename of the first prerequisite.
# $?: The names of all prerequisites that are newer than the target, separated by spaces.
# $^: The filenames of all the prerequisites, separated by spaces.
#     This list has duplicate filenames removed since for most uses, such as compiling, copying, etc., duplicates are not wanted.
# $+: Similar to $^, this is the names of all the prerequisites separated by spaces, except that $+ includes duplicates.
#     This variable was created for specific situations such as arguments to linkers where duplicate values have meaning.
# $*: The stem of the target filename. A stem is typically a filename without its suffix.
#     Its use outside of pattern rules is discouraged.
# -------------------------------------------------------------------------------------------
# Also thanks to https://gist.github.com/maxtruxa/4b3929e118914ccef057f8a05c614b0f
# -------------------------------------------------------------------------------------------

# ============================================================================
# Build
# ============================================================================

# Build related directories
BUILD_DIR := build
OBJS_DIR  := $(BUILD_DIR)/objects
DEPS_DIR  := $(BUILD_DIR)/dependencies

# Creating build directories if they don't exist.
# -p prevent error if a directory already exists.
$(shell mkdir -p $(BUILD_DIR) >/dev/null)
$(shell mkdir -p $(OBJS_DIR) >/dev/null)
$(shell mkdir -p $(DEPS_DIR) >/dev/null)


# ============================================================================
# Source/objects/dependencies files
# ============================================================================

SRCS       := $(shell find ./src -name '*.c')
SRCS_COUNT := $(words $(SRCS))

# Object files, auto generated from source files
OBJS := $(patsubst %,$(OBJS_DIR)/%.o,$(basename $(SRCS)))
# Dependency files, auto generated from source files
DEPS := $(patsubst %,$(DEPS_DIR)/%.d,$(basename $(SRCS)))

# Creating needed sub/folders if they don't exist as they won't be created by compilers
$(shell mkdir -p $(dir $(OBJS)) >/dev/null)
$(shell mkdir -p $(dir $(DEPS)) >/dev/null)


# ============================================================================
# Executable & Compiler flags
# ============================================================================

# Output binary name
BINARY := c-enum-generator

# C Compiler
CC := gcc

# C Version to use
CFLAGS = -std=c23
# Debug flag
CFLAGS += -g
# Warnings
CFLAGS += -Wall -Wextra																\
			 -Wformat=2 -Wno-unused-parameter -Wshadow 						\
          -Wwrite-strings -Wstrict-prototypes -Wold-style-definition \
          -Wredundant-decls -Wnested-externs -Wmissing-include-dirs 	\
    	  	 -Wjump-misses-init -Wlogical-op -fPIC

# Include directories
CFLAGS += -Iinclude

# Linker
LD := gcc
# linker flags
# Pass the flag -export-dynamic to the ELF linker, on targets that support it.
# This instructs the linker to add all symbols, not only used ones, to the dynamic symbol table. This option is needed for some uses of "dlopen" or to allow obtaining backtraces from within a program.
LDFLAGS :=
# linker flags: libraries to link (e.g. -lfoo)
LDLIBS :=
# flags required for dependency generation; passed to compilers
DEPFLAGS = -MT $@ -MD -MP -MF $(DEPS_DIR)/$*.Td


# ============================================================================
# Compilation Steps
# ============================================================================

# compile C source files
COMPILE.c = $(CC) $(DEPFLAGS) $(CFLAGS) -c -o $@
# link object files to binary
LINK.o = $(LD) $(LDFLAGS) $(LDLIBS) -o $@
# precompile step
PRECOMPILE =
# postcompile step
POSTCOMPILE = mv -f $(DEPS_DIR)/$*.Td $(DEPS_DIR)/$*.d


# ============================================================================
# Targets
# ============================================================================

.DEFAULT_GOAL := all

.PHONY: all
all: $(BINARY)

.PHONY: help
help:
	echo available targets: all clean help

# 2> /dev/null || true to avoid printing an error if folders/files don't exist.
.PHONY: clean
clean:
	rm -r $(OBJS_DIR) 2> /dev/null || true
	rm -r $(DEPS_DIR) 2> /dev/null || true
	rm $(BUILD_DIR)/$(BINARY) 2> /dev/null || true

$(BINARY): $(OBJS)
	@$(LINK.o) $^
	@mv -f $(BINARY) $(BUILD_DIR)/$(BINARY)

$(OBJS_DIR)/%.o: %.c
$(OBJS_DIR)/%.o: %.c $(DEPS_DIR)/%.d
	$(PRECOMPILE)
	$(COMPILE.c) $<
	$(POSTCOMPILE)


# The targets which .PRECIOUS depends on are given the following special treatment:
# If make is killed or interrupted during the execution of their recipes, the target is not deleted.
# Also, if the target is an intermediate file, it will not be deleted after it is no longer needed, as is normally done.
.PRECIOUS: $(DEPS_DIR)/%.d
$(DEPS_DIR)/%.d: ;

-include $(DEPS)

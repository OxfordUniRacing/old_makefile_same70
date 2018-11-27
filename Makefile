# Must be the same as msvs project name
OUTPUT_FILE_NAME = projectname

# Flags for debug and release builds
ifndef RELEASE
	CFLAGS += -g3 -O0
	DEFS += -DDEBUG
else
	CFLAGS += -g3 -O2 -flto
	LDFLAGS += -flto
endif

# Compile flags
CFLAGS += -Wall -Wextra
CFLAGS += -Wmissing-prototypes -Wstrict-prototypes
CFLAGS += -fno-common -ffunction-sections -std=gnu99
CPPFLAGS += -MD -MP
LDFLAGS += --static -Wl,--gc-sections -ffunction-sections

# Target specific flags
ARCH_FLAGS := -mthumb -mcpu=cortex-m7 -mfloat-abi=hard -mfpu=fpv5-d16
LDFLAGS += -Tsame70a/startup/same70q21_flash.ld
DEFS += -D__SAME70Q21__

subdirs = $(patsubst %/,%,$(filter %/,$(wildcard $(1)/*/)))

# Source directories
SRC_DIRS := \
same70a/startup \
$(call subdirs,hpl) \
hal/utils/src \
hal/src \
.

# Include directories
INC_DIRS := \
CMSIS/Include \
same70a/include \
hri \
$(call subdirs,hpl) \
hal/utils/include \
hal/include \
config \
.

BUILD_DIR := build

SRCS := $(foreach dir,$(SRC_DIRS),$(wildcard $(dir)/*.c))
OBJS := $(SRCS:%.c=$(BUILD_DIR)/%.o)
DEPS := $(OBJS:.o=.d)
INCS := $(INC_DIRS:%=-I%)
CPPFLAGS += $(DEFS) $(INCS)

PREFIX ?= arm-none-eabi
CC := $(PREFIX)-gcc
CXX := $(PREFIX)-g++
LD := $(PREFIX)-gcc
OBJCOPY := $(PREFIX)-objcopy
SIZE := $(PREFIX)-size

# Be silent per default, but 'make V=1' will show all compiler calls.
ifneq ($(V),1)
Q := @
NULL := 2>/dev/null
endif

all: directories $(OUTPUT_FILE_NAME).elf

$(BUILD_DIR)/%.o: %.c
	@printf "  CC      $(^)\n"
	$(Q)$(CC) $(CPPFLAGS) $(CFLAGS) $(ARCH_FLAGS) -o $(@) -c $(^)

%.elf: $(OBJS)
	@printf "  LD      $(@)\n"
	$(Q)$(LD) $(LDFLAGS) $(ARCH_FLAGS) -o $(@) $(^)
	$(Q)$(OBJCOPY) -O binary $(@) $(BUILD_DIR)/$(*).bin
	$(Q)$(OBJCOPY) -O ihex $(@) $(BUILD_DIR)/$(*).hex
	$(Q)cp $(@) $(BUILD_DIR)/
	$(Q)$(SIZE) $(@)

clean:
	@printf "  CLEAN\n"
	$(Q)rm -rf $(BUILD_DIR)
	$(Q)rm -f $(OUTPUT_FILE_NAME).elf

directories:
	$(Q)"mkdir" -p $(SRC_DIRS:%=$(BUILD_DIR)/%)

.PHONY: all clean directories
.SECONDARY:

-include $(DEPS)

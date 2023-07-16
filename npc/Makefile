TOPNAME = ysyx_22051086_top
INC_PATH ?=

VERILATOR = verilator
VERILATOR_CFLAGS += -MMD --build -cc --exe --trace -j 1  -Wall  \
				-O3 --x-assign fast --x-initial fast --noassert 

BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)

default: $(BIN)

$(shell mkdir -p $(BUILD_DIR))

# project source
VSRCS = $(shell find $(abspath ./vsrc) -name "*.v" -or -name "*.sv")
CSRCS = $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")

# rules for verilator
INCFLAGS = $(addprefix -I, $(INC_PATH))
CFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""  -g
LDFLAGS += -fsanitize=address -lSDL2 -lSDL2_image
CFLAGS += $(shell llvm-config-11 --cxxflags) -fPIE
LDFLAGS += $(shell llvm-config-11 --libs)



all:
	@echo "Write this Makefile by your self."

X=main.cpp
Y=ysyx_22051086_top.v
Z=ysyx_22051086_top
sim:$(VSRCS) $(CSRCS) 
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) -o $(abspath $(BIN))
	./build/$(Z) $(ARGS) $(IMG)
	#gtkwave dump.vcd

run: $(BIN)
	@$^

clean:
	rm dump.vcd
	rm -r build
	
include ../Makefile



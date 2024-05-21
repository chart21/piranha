# General configuration
BINARY = $(BINARY)
DEBUG_BINARY = piranha-debug
BUILD_DIR = build
DEBUG_DIR = debug
CUDA_PATH = /usr/local/cuda-12.1
CUTLASS_PATH = ext/cutlass

# Compiler and flags
CXX = $(CUDA_PATH)/bin/nvcc
FLAGS := -Xcompiler="-O3,-w,-pthread,-msse4.1,-maes,-msse2,-mpclmul,-fpermissive,-fpic" -Xcudafe "--diag_suppress=declared_but_not_referenced" --std=c++14
DEBUG_FLAGS := -Xcompiler="-O0,-g,-w,-pthread,-msse4.1,-maes,-msse2,-mpclmul,-fpermissive,-fpic" -Xcudafe "--diag_suppress=declared_but_not_referenced" --std=c++14
PIRANHA_FLAGS :=

# Include and library directories
OBJ_INCLUDES := -I '$(CUDA_PATH)/include' \
                -I '$(CUTLASS_PATH)/include' \
                -I '$(CUTLASS_PATH)/tools/util/include' \
                -I 'include'
LIBS := -lcrypto -lssl -lcudart -lcuda -lgtest -lcublas
INCLUDES := $(OBJ_INCLUDES) -L./ -L$(CUDA_PATH)/lib64 -L$(CUTLASS_PATH)/build/tools/library

# Source files
VPATH = src/:src/gpu:src/nn:src/mpc:src/util:src/test
SRC_CPP_FILES = $(wildcard src/*.cpp src/**/*.cpp)
SRC_CU_FILES = $(filter-out src/main64.cu src/main32.cu src/main16.cu, $(wildcard src/*.cu src/**/*.cu))
OBJ_FILES = $(addprefix $(BUILD_DIR)/, $(notdir $(SRC_CPP_FILES:.cpp=.o)) $(notdir $(SRC_CU_FILES:.cu=.o)))
DEBUG_OBJ_FILES = $(addprefix $(DEBUG_DIR)/, $(notdir $(SRC_CPP_FILES:.cpp=.o)) $(notdir $(SRC_CU_FILES:.cu:.o)))
HEADER_FILES = $(wildcard src/*.h src/**/*.h src/*.cuh src/**/*.cuh src/*.inl src/**/*.inl)

# Main file selection
ifeq ($(BITLENGTH), 32)
    MAIN_FILE = main32.cu
    MAIN_OBJ = $(BUILD_DIR)/main32.o
else ifeq ($(BITLENGTH), 16)
    MAIN_FILE = main16.cu
    MAIN_OBJ = $(BUILD_DIR)/main16.o
else
    # Default to 64 if BITLENGTH is not specified or is set to 64
    MAIN_FILE = main64.cu
    MAIN_OBJ = $(BUILD_DIR)/main64.o
endif

# Targets
all: $(BINARY)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BINARY): $(BUILD_DIR) $(OBJ_FILES) $(MAIN_OBJ)
	$(CXX) $(FLAGS) $(PIRANHA_FLAGS) -o $@ $(OBJ_FILES) $(MAIN_OBJ) $(INCLUDES) $(LIBS)

$(BUILD_DIR)/%.o: %.cpp $(HEADER_FILES)
	$(CXX) -dc $(FLAGS) $(PIRANHA_FLAGS) -c $< -o $@ $(OBJ_INCLUDES)

$(BUILD_DIR)/%.o: %.cu $(HEADER_FILES)
	$(CXX) -dc $(FLAGS) -Xcompiler="$(PIRANHA_FLAGS)" -c $< -o $@ $(OBJ_INCLUDES)

$(MAIN_OBJ): src/$(MAIN_FILE) $(HEADER_FILES)
	$(CXX) -dc $(FLAGS) -c $< -o $@ $(OBJ_INCLUDES)

$(DEBUG_DIR):
	mkdir -p $(DEBUG_DIR)

clean:
	rm -rf $(BINARY) $(BUILD_DIR) $(DEBUG_DIR)

# Additional targets and commands for running and debugging
run: $(BINARY)
	@./$(BINARY) 3 $(CONFIG_FILE) --gtest_filter=$(TEST) >/dev/null 2>&1 &
	@./$(BINARY) 2 $(CONFIG_FILE) --gtest_filter=$(TEST) >/dev/null 2>&1 &
	@./$(BINARY) 1 $(CONFIG_FILE) --gtest_filter=$(TEST) >/dev/null 2>&1 &
	@./$(BINARY) 0 $(CONFIG_FILE) --gtest_filter=$(TEST)
	@echo "Execution completed"

# Define other rules like gdb, memcheck, and party similar to run target
# with specific adjustments if necessary


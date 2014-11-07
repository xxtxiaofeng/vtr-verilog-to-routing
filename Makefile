#Tools
CXX = g++
AR = ar
LEXER_GEN = flex
PARSER_GEN = bison

#Whether this is a debug (symbols, no opt) or
# release (no symbols, opt) build. May be 
# inherited from build environment. Can
# override by defining below.
#
# Can be 'debug' or 'release'
#BUILD_TYPE = release

# How verbose we want the make file
#  0: print nothing
#  1: print high-level message
#  2: print high-level message + detailed command
VERBOSITY = 1


#Verbosity Configuration
vecho_0 = true
vecho_1 = echo
vecho_2 = echo
vecho = $(vecho_$(VERBOSITY))

AT_0 := @
AT_1 := @
AT_2 := 
AT = $(AT_$(VERBOSITY))

#Final output files
EXE=sta
STATIC_LIB=libsta.a

#Directories
SRC_DIR = src
BUILD_DIR = build

DIRS = $(SRC_DIR)/timing_graph $(SRC_DIR)/parsers

#Flags
WARN_FLAGS = -Wall -Wpointer-arith -Wcast-qual -D__USE_FIXED_PROTOTYPES__ -ansi -pedantic -Wshadow -Wcast-align -D_POSIX_SOURCE -Wno-write-strings

DEP_FLAGS = -MMD -MP

DEBUG_FLAGS = -g -ggdb3 -g3 -O0 -fno-inline

OPT_FLAGS = -O3

ifneq (,$(findstring release, $(BUILD_TYPE)))
	DEBUG_OPT_FLAGS := $(OPT_FLAGS)
else
	DEBUG_OPT_FLAGS := $(DEBUG_FLAGS)
endif

CFLAGS = $(DEP_FLAGS) $(WARN_FLAGS) $(DEBUG_OPT_FLAGS) $(INC_FLAGS) --std=c++11

#Objects
MAIN_SRC = $(SRC_DIR)/main.cpp
MAIN_OBJ := $(foreach src, $(MAIN_SRC), $(patsubst $(SRC_DIR)/%.cpp, $(BUILD_DIR)/%.o, $(src)))

LIB_SRC = $(foreach dir, $(DIRS), $(wildcard $(dir)/*.cpp))
LIB_OBJ := $(foreach src, $(LIB_SRC), $(patsubst $(SRC_DIR)/%.cpp, $(BUILD_DIR)/%.o, $(src)))

LEXER_SRC = $(foreach dir, $(DIRS), $(wildcard $(dir)/*.l))
LEXER_GEN_SRC = $(patsubst $(SRC_DIR)/%.l, $(BUILD_DIR)/%.lex.c, $(LEXER_SRC))
LEXER_GEN_OBJ = $(foreach gen_src, $(LEXER_GEN_SRC), $(patsubst %.c, %.o, $(gen_src)))

PARSER_SRC = $(foreach dir, $(DIRS), $(wildcard $(dir)/*.y))
PARSER_GEN_SRC = $(patsubst $(SRC_DIR)/%.y, $(BUILD_DIR)/%.parse.c, $(PARSER_SRC))
PARSER_GEN_OBJ = $(foreach gen_src, $(PARSER_GEN_SRC), $(patsubst %.c, %.o, $(gen_src)))

OBJECTS_LIB = $(LIB_OBJ) $(LEXER_GEN_OBJ) $(PARSER_GEN_OBJ)
OBJECTS_EXE = $(MAIN_OBJ) $(OBJECTS_LIB)

SRC_INC_FLAGS = $(foreach inc_dir, $(DIRS), $(patsubst %, -I%, $(inc_dir)))

#Need to include obj dir since it includes any generated source/header files
INC_FLAGS = -I$(SRC_DIR) -I$(BUILD_DIR) $(SRC_INC_FLAGS)

#Dependancies
DEP = $(OBJECTS_EXE:.o=.d)

-include $(DEP)

#
#Rules
#
.PHONY: clean

#Don't delete intermediate files
.SECONDARY:

all: $(EXE) $(STATIC_LIB)
	@echo $(main_src)

$(EXE): $(OBJECTS_EXE)
	@$(vecho) "Linking executable: $@"
	$(AT) $(CXX) $(CFLAGS) -o $@ $(OBJECTS_EXE)

$(STATIC_LIB): $(OBJECTS_LIB)
	@$(vecho) "Linking static library: $@"
	$(AT) $(AR) rcs $@ $(OBJECTS_LIB)

build/%.lex.c: src/%.l
	@$(vecho) "Generating Lexer $< ..."
	@mkdir -p $(@D)
	$(AT) $(LEXER_GEN) -o $@ $<

build/%.parse.c build/%.parse.h: src/%.y
	@$(vecho) "Generating Parser $< ..."
	@mkdir -p $(@D)
	$(AT) $(PARSER_GEN) -d $< -o $(BUILD_DIR)/$*.parse.c 

build/%.lex.o: build/%.lex.c build/%.parse.h
	@$(vecho) "Compiling Lexer $< ..."
	$(AT) $(CXX) $(CFLAGS) -c $< -o $@

build/%.parse.o: build/%.parse.c
	@$(vecho) "Compiling Parser $< ..."
	$(AT) $(CXX) $(CFLAGS) -c $< -o $@

build/%.o: src/%.cpp
	@$(vecho) "Compiling Source $< ..."
	@mkdir -p $(@D)
	$(AT) $(CXX) $(CFLAGS) -c $< -o $@

clean:
	@$(vecho) "Cleaning..."
	$(AT) rm -f $(LEXER_GEN_SRC)
	$(AT) rm -f $(PARSER_GEN_SRC)
	$(AT) rm -f $(DEP)
	$(AT) rm -rf $(BUILD_DIR)
	$(AT) rm -f $(EXE)
	$(AT) rm -f $(STATIC_LIB)

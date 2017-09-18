SRC := $(wildcard ../src/*.c ../src/*.s)
FORTH_SRC := $(wildcard ../src/*.fs) 

all: build/back.hex

build/back.o:  $(SRC) $(FORTH_SRC) 
	mkdir -p build
	arm-none-eabi-as -mthumb $(SRC) -o $@

build/back.elf:  build/back.o
	arm-none-eabi-ld  -M=build/back.map -T/home/back/back/gcc_arm.ld build/back.o -o build/back.elf

build/back.hex: build/back.elf
	@echo Preparing: $@
	arm-none-eabi-objcopy -O ihex $< $@

clean:
	rm -rf build

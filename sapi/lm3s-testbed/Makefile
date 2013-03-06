# Make a binary for the hacked-up hello world
# for the Luminary Micro LM3S608

AS=arm-none-eabi-as
CC=arm-none-eabi-gcc
LD=arm-none-eabi-ld
COPY=arm-none-eabi-objcopy
PART=LM3S608

VPATH+=../lm/utils
VPATH+=../lm/boot_loader

IPATH+=-I.
IPATH+=-I..
IPATH+=-I../../../lm3s/SW-LM3S-9107/
IPATH+=-I../../../lm3s/SW-LM3S-9107/utils
VPATH+=..
VPATH+=../../../lm3s/SW-LM3S-9107/utils
VPATH+=../../../cm3lib

CFLAGS= -mthumb         \
	-mcpu=cortex-m3 \
	-DCPUHZ=50000000 \
	-DTICKHZ=100 \
	-DTICKMS=10 \
	-DFORTH_ADDR=0x20000 \
	-DPLATFORM_LM3S \
	-Os             \
	-Wall		\
	-Werror		\
	-MD             \
	-std=c99        \
	-Wall           \
	-pedantic       \
	-DPART_${PART}  \
	-Dgcc		\
	${IPATH}        \
	-g		\
	-c

ASFLAGS  = -mcpu=cortex-m3 -mthumb -mthumb-interwork -I.
ASFLAGS += $(ADEFS)
#ASFLAGS += -Wa,-adhlns=$(addsuffix .lst)
#ASFLAGS +=  -g$(DEBUG)
ASFLAGS += $(patsubst %,-I%,$(EXTRAINCDIRS))

LDFLAGS=--gc-sections -L../lm/src/gcc
UTILS=uartstdio.o userapp.o syscalls.o dylink.o sapi-uart-lm3s.o

all: sapi-host.bin

%.bin: %.axf
	${COPY} -O binary $^ $@
sapi-host.axf: main.o startup_gcc.o svc.o ${SUPPORT} ${UTILS}
	${LD} -T static.ld --entry ResetISR --gc-sections -o $@ $^ \
		../../../lm3s/SW-LM3S-9107/driverlib/gcc-cm3/libdriver-cm3.a
clean:
	rm -f *.o *.bin *.axf *.d


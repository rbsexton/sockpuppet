# ######################################################################
# A strange makefile with lots of history.
# ######################################################################

AS=arm-none-eabi-as
ASMFLAGS = -mcpu=cortex-m3 -mthumb -mapcs-32  -gstabs

OBJDUMP=arm-none-eabi-objdump
OBJCOPY=arm-none-eabi-objcopy

LD=arm-none-eabi-ld
LNKFLAGS =  -v -T lm3s.ld -nostartfiles

STELLARISWARE=../../glowball/lm
CC=arm-none-eabi-gcc
CFLAGS=-O2 -mcpu=cortex-m3 -mthumb -gstabs -I$(STELLARISWARE) 

.PRECIOUS: %.o %.bin %.axf %.s

all: sp.bin app.bin
#all: client.bin

clean:
	@ echo "...cleaning"
	rm -f *.o *.elf *.hex *.bin *.lst *.lnkh *.lnkt *.ldout *.axf *.dump
%.s: %.asm
	$(PREASM) $*.asm $@
%.o: %.s 
	$(AS) $(ASMFLAGS) -ahls=$*.lst  -o $@ $*.s
%.dis: %.axf
	$(OBJDUMP) -d --source $<  > $@
%.bin: %.axf
	$(OBJCOPY) -O binary $<  $*.bin
sp.axf: crt0.o svc.o syscalls.o sp.o sapi.o
	@ echo "...linking $@"
	${LD} -M -T sp.ld --entry ResetISR --gc-sections -o $@ $^ \
	                $(STELLARISWARE)/driverlib/gcc/libdriver.a > sp.ldout
app.axf: app_crt0.o app_main.o sapi.o
	@ echo "...linking $@"
	${LD} -M -T app.ld --entry ResetISR --gc-sections -o $@ $^ > app.ldout



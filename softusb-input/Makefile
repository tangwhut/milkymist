SOURCES=crt0.S main.c debug.c crc.c libc.c

all: softusb-input.bin

%.bin: %.elf
	avr-objcopy -O binary $< $@

softusb-input.elf: $(SOURCES) $(wildcard *.h)
	avr-gcc -o softusb-input.elf -mmcu=avr2 -mno-interrupts -Wall -Os $(SOURCES) $(CFLAGS) -nostdlib -Wl,-T -Wl,navre.ld

.PHONY: clean

clean:
	rm -f softusb-input.bin softusb-input.elf

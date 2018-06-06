TMP = tmp
ASM = mipsel-linux-gnu-gcc -c -O0 -Wall -msoft-float -mips1
CC  = mipsel-linux-gnu-gcc -std=c11 -c -O2 -Wall -nostdlib -mno-memcpy -static -msoft-float -mips1
VCS = vcs -full64 -v2005 -Wall -LDFLAGS -no-pie

LDFLAGS  = -T cld-mips.ld -nostdlib -static
OCFLAGS  = -O verilog --reverse-bytes=4

.PRECIOUS: %.imem %.dmem

simv: *.v
	$(VCS) *.v -o simv

start-%.o: %.o startup.o
	mipsel-linux-gnu-ld $(LDFLAGS) $^ -o $@

%.o: %.c
	$(CC) $< -o $@
%.o: %.s
	$(ASM) $< -o $@

%.imem : start-%.o
	mipsel-linux-gnu-objcopy $(OCFLAGS) \
		-j .startup \
		-j .init \
		-j .text \
		$< $<.itext
	cp $<.itext $@
	ln -sf $@ main.imem

%.dmem : start-%.o
	mipsel-linux-gnu-objcopy $(OCFLAGS) \
		-j .rodata \
		-j .data \
		-j .bss \
		--change-addresses -0x10000000 \
		$< $<.dtext
	cp $<.dtext $@
	ln -sf $@ main.dmem


#sed -E "s/(([0-9A-F]{2}) )/\2/g" < $<.text | sed -E "s/([0-9A-F]{8})/\1\n/g" | sed -E "s/\r//g" | sed "/^$$/d" > $@

%.mem: %.imem %.dmem
	:

clean:
	rm -f simv *.o *.[id]mem *.[id]text
	rm -rf simv.daidir csrc

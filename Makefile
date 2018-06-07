TMP = tmp
ASM = mipsel-linux-gnu-gcc -c -O0 -Wall -msoft-float -march=mips1 -mtune=r4000
CC  = mipsel-linux-gnu-gcc -std=c11 -c -O2 -Wall -nostdlib -mno-memcpy -static -msoft-float -march=mips1 -mtune=r4000
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
		-j .ctors \
		-j .dtors \
		$< $@
	sed -i -E -e "s/([0-9A-F]) /\1/g" -e "s/([0-9A-F]{8})/\1\n/g" $@
	sed -i -E -e "/^\r/d" $@
	perl -pi -e 's/^@([0-9A-F]+)/sprintf "@%x", hex($$1)\/4/ge' $@
	ln -sf $@ imem.mem

%.dmem : start-%.o
	mipsel-linux-gnu-objcopy $(OCFLAGS) \
		-j .simdebug \
		-j .rodata \
		-j .data \
		-j .bss \
		--change-addresses -0x10000000 \
		$< $@
	sed -i -E -e "s/([0-9A-F]) /\1/g" -e "s/([0-9A-F]{8})/\1\n/g" $@
	sed -i -E -e "/^\r/d" $@
	perl -pi -e 's/^@([0-9A-F]+)/sprintf "@%x", hex($$1)\/4/ge' $@
	ln -sf $@ dmem.mem



%.mem: %.imem %.dmem
	:

clean:
	rm -f simv *.o *.[id]mem *.[id]text
	rm -rf simv.daidir csrc

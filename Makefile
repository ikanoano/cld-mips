TMP = tmp
ASM = mipsel-linux-gnu-gcc -c -O0 -Wall
VCS = vcs -full64 -v2005 -Wall -LDFLAGS -no-pie

simv: *.v
	$(VCS) *.v -o simv

%.o: %.s
	$(ASM) $< -o $@

%.mem: %.o
	mipsel-linux-gnu-objcopy -O verilog --only-section=.text --reverse-bytes=4 $< $<.text
	sed -E "s/(([0-9A-F]{2}) )/\2/g" < $<.text | sed -E "s/([0-9A-F]{8})/\1\n/g" | sed -E "s/\r//g" | sed "/^$$/d" > $@

clean:
	rm -f simv
	rm -rf simv.daidir csrc

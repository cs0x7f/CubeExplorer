src:= CommandMain.pas CubeDefs.pas Search.pas CordCube.pas MathFuncs.pas CubiCube.pas Symmetries.pas FaceCube.pas

all: CommandMain CommandMainHuge

CommandMain: $(src)
	rm -f *.o *.ppu
	fpc -uHUGE -Mobjfpc -O3 -oCommandMain CommandMain.pas 

CommandMainHuge: $(src)
	rm -f *.o *.ppu
	fpc -dHUGE -Mobjfpc -O3 -oCommandMainHuge CommandMain.pas

clean:
	rm -f *.o *.ppu CommandMain CommandMainHuge

.PHONY: all clean

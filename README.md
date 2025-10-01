## For Apple M Series CPU only

### build instructions
as -o tutorial.o apple_silicon_tutorial.s
ld -o tutorial tutorial.o -lSystem \
   -syslibroot `xcrun -sdk macosx --show-sdk-path` \
   -e _main -arch arm64
./tutorial

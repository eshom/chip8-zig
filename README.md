# TBD

# Raylib build instructions
```bash
cd vendor/raylib/src
make PLATFORM=PLATFORM_DESKTOP CUSTOM_CFLAGS=-DSUPPORT_CUSTOM_FRAME_CONTROL=1
```

# TODO
- Implement all instructions
- Dynamic configuration
- Complete test suite

# Credits
- Tobia's guide has been an invaluable source: [https://tobiasvl.github.io/blog/write-a-chip-8-emulator](https://tobiasvl.github.io/blog/write-a-chip-8-emulator)
- Timendus' test suite: [https://github.com/Timendus/chip8-test-suite](https://github.com/Timendus/chip8-test-suite)

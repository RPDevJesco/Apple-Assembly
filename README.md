# Apple Silicon Assembly Language Tutorial

A comprehensive, executable tutorial for learning ARM64 assembly programming on Apple Silicon Macs. This project contains extensively commented code that teaches ARM64 architecture from the ground up, with working examples you can assemble, run, and modify.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Tutorial Contents](#tutorial-contents)
- [Building and Running](#building-and-running)
- [Key Concepts Covered](#key-concepts-covered)
- [Code Examples Explained](#code-examples-explained)
- [VSCode Integration](#vscode-integration)
- [Learning Path](#learning-path)
- [Debugging](#debugging)
- [Resources](#resources)
- [Contributing](#contributing)

## 🎯 Overview

This tutorial is designed as a **single, executable assembly file** that teaches ARM64 assembly programming through comprehensive comments and working code examples. Unlike typical tutorials that show isolated snippets, this entire file assembles and runs, demonstrating real-world assembly programming.

**What makes this tutorial unique:**
- Every section is executable code, not pseudocode
- Extensive inline comments explain the "why" not just the "what"
- Progressive complexity: starts simple, builds to advanced topics
- Practical examples: string length, Fibonacci, SIMD operations
- Real system calls that interact with macOS

## ✅ Prerequisites

**Hardware:**
- Apple Silicon Mac (M1, M2, M3, M4, or later)

**Software:**
- macOS (any recent version)
- Xcode Command Line Tools
- VSCode (optional, but recommended)

**Install Command Line Tools:**
```bash
xcode-select --install
```

**Verify installation:**
```bash
as --version
ld --version
```

## 🚀 Quick Start

**1. Clone or download this project**

**2. Build and run from terminal:**
```bash
as -o tutorial.o apple_silicon_tutorial.s
ld -o tutorial tutorial.o -lSystem -syslibroot `xcrun -sdk macosx --show-sdk-path` -e _main -arch arm64
./tutorial
```

**3. Or use VSCode:**
- Open `apple_silicon_tutorial.s`
- Press `Cmd+Shift+B` to build and run

**Expected output:**
```
Hello, World!
```

The program demonstrates various assembly operations and exits cleanly with status 0.

## 📁 Project Structure

```
.
├── apple_silicon_tutorial.s    # Main tutorial file (comprehensive assembly code)
├── .vscode/
│   └── tasks.json             # VSCode build configuration
└── README.md                  # This file
```

## 📚 Tutorial Contents

The tutorial is organized into 13 major sections:

### Section 1: Introduction to ARM64 Architecture
- RISC vs CISC architecture
- Fixed instruction width (32-bit)
- Load-store architecture
- Register-rich design

### Section 2: Understanding Registers
- 31 general-purpose registers (X0-X30)
- Special registers (SP, LR, PC, FP)
- Register sizes (64-bit X, 32-bit W)
- Calling conventions (ABI)
- Register preservation rules

### Section 3: Basic Data Movement
- MOV instructions
- Immediate value loading
- Building 64-bit constants with MOVZ/MOVK
- Zero register usage

### Section 4: Arithmetic Operations
- Addition (ADD, ADDS)
- Subtraction (SUB, SUBS)
- Multiplication (MUL, SMULL, UMULL)
- Division (SDIV, UDIV)
- Modulo computation
- Multiply-accumulate operations

### Section 5: Logical Operations and Bit Manipulation
- Bitwise AND, OR, XOR, NOT
- Shifts (LSL, LSR, ASR, ROR)
- Bit field operations (UBFX, SBFX, BFI)
- Bit counting (CLZ)
- Bit and byte reversal

### Section 6: Memory Operations
- Load instructions (LDR, LDRH, LDRB)
- Store instructions (STR, STRH, STRB)
- Sign extension (LDRSW, LDRSH, LDRSB)
- Addressing modes (base, offset, pre/post-indexed)
- Load/store pairs (LDP, STP)
- Memory alignment requirements

### Section 7: Control Flow
- Unconditional branches (B, BR, BL, BLR)
- Conditional branches (B.EQ, B.NE, B.LT, etc.)
- Compare and branch (CBZ, CBNZ)
- Test bit and branch (TBZ, TBNZ)

### Section 8: Condition Flags
- NZCV register (Negative, Zero, Carry, oVerflow)
- Flag-setting operations
- Conditional select (CSEL, CSINC, CSET)
- Overflow detection

### Section 9: Floating Point and SIMD
- FP registers (V0-V31, accessed as D, S, H, B, Q)
- Floating point arithmetic
- FP conversions
- NEON/SIMD vector operations
- Parallel processing examples

### Section 10: String Length Implementation
- Practical example: strlen() in assembly
- Loop construction
- Null-terminator detection

### Section 11: Fibonacci Implementation
- Recursive function example
- Stack frame management
- Callee-saved register handling

### Section 12: SIMD Array Sum
- Processing 4 integers in parallel
- Vector loads and operations
- Horizontal reduction

### Section 13: System Calls
- macOS BSD syscall interface
- write() for console output
- exit() for program termination

## 🔨 Building and Running

### Manual Build (Terminal)

**Assemble:**
```bash
as -o tutorial.o apple_silicon_tutorial.s
```

**Link:**
```bash
ld -o tutorial tutorial.o \
   -lSystem \
   -syslibroot `xcrun -sdk macosx --show-sdk-path` \
   -e _main \
   -arch arm64
```

**Run:**
```bash
./tutorial
```

**Check exit status:**
```bash
echo $?
# Should output: 0
```

### VSCode Build (Automated)

1. Open `apple_silicon_tutorial.s` in VSCode
2. Press `Cmd+Shift+B` (default build task)
3. The program will assemble, link, and run automatically

**Available tasks:**
- **Build and Run** (default): Compiles and executes
- **Build Only**: Just assembles and links
- **Assemble**: Creates object file only
- **Link**: Links existing object file

## 🎓 Key Concepts Covered

### ARM64 Architecture Fundamentals

**RISC Design:**
- All instructions are exactly 32 bits (4 bytes)
- Simpler, faster instruction execution
- More instructions needed but pipeline-friendly

**Load-Store Architecture:**
```asm
// You CANNOT do this (no direct memory arithmetic):
// add x0, x0, [x1]

// You MUST do this:
ldr  x2, [x1]      // Load from memory
add  x0, x0, x2    // Operate on registers
str  x0, [x1]      // Store back to memory
```

### Register Usage and ABI

**Function Arguments:**
- X0-X7: First 8 arguments
- Additional arguments: Stack
- X0: Return value

**Preserved Registers:**
- X19-X28: Must save if you use them
- X29 (FP): Frame pointer
- X30 (LR): Link register

**Scratch Registers:**
- X0-X18: Can be freely modified
- Don't expect them to survive function calls

### Stack Frame Pattern

Every function follows this pattern:

```asm
my_function:
    // PROLOGUE: Save registers and set up frame
    stp  x29, x30, [sp, #-16]!   // Save FP and LR
    mov  x29, sp                  // Set new frame pointer
    
    // ... function body ...
    
    // EPILOGUE: Restore and return
    ldp  x29, x30, [sp], #16      // Restore FP and LR
    ret                           // Return to caller
```

### Condition Flags

**NZCV Register:**
- **N**: Result is negative (bit 63 = 1)
- **Z**: Result is zero
- **C**: Unsigned overflow/carry
- **V**: Signed overflow

**Set by:**
- Instructions with 'S' suffix (ADDS, SUBS, ANDS)
- Compare instructions (CMP, CMN, TST)

**Example:**
```asm
mov   x0, #10
mov   x1, #20
cmp   x0, x1        // Sets flags based on x0 - x1
b.lt  is_less       // Branch if x0 < x1 (signed)
b.lo  is_lower      // Branch if x0 < x1 (unsigned)
```

## 💡 Code Examples Explained

### Example 1: Building 64-bit Constants

ARM64 instructions are 32 bits, so large constants require multiple instructions:

```asm
// Build 0xEF01ABCD12345678 piece by piece
movz  x3, #0x5678, lsl #0      // Bits 0-15:  0x0000000000005678
movk  x3, #0x1234, lsl #16     // Bits 16-31: 0x0000000012345678
movk  x3, #0xABCD, lsl #32     // Bits 32-47: 0x0000ABCD12345678
movk  x3, #0xEF01, lsl #48     // Bits 48-63: 0xEF01ABCD12345678
```

- **MOVZ**: Move with Zero (clears other bits)
- **MOVK**: Move with Keep (preserves other bits)

### Example 2: Computing Modulo

ARM64 has division but no modulo instruction:

```asm
// Compute x0 % x1 (x0 mod x1)
udiv  x2, x0, x1     // x2 = x0 / x1
msub  x3, x2, x1, x0 // x3 = x0 - (x2 * x1)
// Result: x3 = x0 % x1

// Formula: a % b = a - (a/b) * b
```

### Example 3: Strlen Implementation

```asm
strlen_asm:
    mov   x1, #0              // counter = 0
strlen_loop:
    ldrb  w2, [x0, x1]        // load byte at string[counter]
    cbz   w2, strlen_done     // if byte == 0, done
    add   x1, x1, #1          // counter++
    b     strlen_loop         // continue
strlen_done:
    mov   x0, x1              // return counter
    ret
```

**Key techniques:**
- `ldrb`: Load byte (8-bit)
- `cbz`: Compare and Branch if Zero
- Base + offset addressing: `[x0, x1]`

### Example 4: SIMD Vector Addition

Process 4 integers simultaneously:

```asm
// Load vectors
dup   v0.4s, w5        // v0 = [1, 1, 1, 1]
dup   v1.4s, w6        // v1 = [2, 2, 2, 2]

// Add in parallel
add   v2.4s, v0.4s, v1.4s  // v2 = [3, 3, 3, 3]
```

**Performance:**
- 1 instruction = 4 additions
- 4x faster than scalar code
- Essential for graphics, audio, ML

## 🔧 VSCode Integration

The project includes a pre-configured `.vscode/tasks.json` that provides:

**Build Tasks:**
- `Cmd+Shift+B`: Build and run (default)
- `Cmd+Shift+P` → "Tasks: Run Build Task" for specific tasks

**Task Configuration:**
```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Assemble",
            "command": "as",
            "args": ["-o", "${fileDirname}/${fileBasenameNoExtension}.o", "${file}"]
        },
        {
            "label": "Link",
            "command": "ld -o ${fileDirname}/${fileBasenameNoExtension} ...",
            "dependsOn": ["Assemble"]
        }
    ]
}
```

**Features:**
- Automatic dependency management
- Error reporting in Problems panel
- Integrated terminal output
- One-key building

## 📖 Learning Path

**Recommended progression:**

1. **Read Section 1-2**: Understand architecture and registers
2. **Run the code**: See it work before diving deep
3. **Section 3-5**: Master data movement and arithmetic
4. **Modify examples**: Change values, add operations
5. **Section 6-7**: Learn memory and control flow
6. **Write functions**: Create your own implementations
7. **Section 8-9**: Advanced topics (flags, FP, SIMD)
8. **Sections 10-12**: Study practical examples
9. **Section 13**: System calls and OS interaction

**Exercises:**

1. **Modify strlen**: Make it count only alphabetic characters
2. **Iterative Fibonacci**: Convert the recursive version to iterative
3. **Array Maximum**: Write a function to find max value in array
4. **SIMD Multiply**: Create a vector multiplication function
5. **String Copy**: Implement strcpy() in assembly

## 🐛 Debugging

### Using LLDB

**Start debugger:**
```bash
lldb ./tutorial
```

**Set breakpoint at main:**
```
(lldb) b _main
(lldb) run
```

**Examine registers:**
```
(lldb) register read
(lldb) register read x0
(lldb) register read --all
```

**Step through code:**
```
(lldb) si        # Step instruction
(lldb) ni        # Next instruction (skip calls)
(lldb) c         # Continue
```

**Examine memory:**
```
(lldb) x/16xb 0x...     # 16 bytes in hex
(lldb) memory read 0x...
```

### Common Issues

**Issue: "library 'System' not found"**
- Cause: SDK path not found
- Fix: Verify Xcode Command Line Tools installed
- Check: `xcrun -sdk macosx --show-sdk-path`

**Issue: Segmentation fault**
- Cause: Unaligned memory access or stack corruption
- Debug: Use LLDB to find exact instruction
- Check: Stack alignment (must be 16-byte aligned)

**Issue: Wrong output**
- Cause: Register confusion or incorrect flags
- Debug: Print intermediate values using syscalls
- Verify: Register usage follows ABI

## 📚 Resources

### Official Documentation
- [ARM Architecture Reference Manual](https://developer.arm.com/documentation/ddi0487/latest)
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Procedure Call Standard for ARM64](https://github.com/ARM-software/abi-aa/blob/main/aapcs64/aapcs64.rst)

### Tools
- [Compiler Explorer (Godbolt)](https://godbolt.org/) - See C compiled to assembly
- [ARM Instruction Set Reference](https://developer.arm.com/documentation/ddi0602/latest)
- LLDB Debugger - Built into macOS

### Books
- "Programming with 64-Bit ARM Assembly Language" by Stephen Smith
- "Computer Organization and Design ARM Edition" by Patterson & Hennessy

### Online Communities
- [ARM Community Forums](https://community.arm.com/)
- [Stack Overflow - ARM tag](https://stackoverflow.com/questions/tagged/arm)

## 🤝 Contributing

This is an educational project. Contributions are welcome:

**Ideas for contributions:**
- Additional practical examples
- More detailed explanations of complex topics
- Exercises with solutions
- Performance optimization examples
- Additional helper functions

## 📝 License

This tutorial is provided as-is for educational purposes. Feel free to use, modify, and share.

## 🎉 Acknowledgments

Created as a comprehensive learning resource for Apple Silicon assembly programming. Special thanks to the ARM and Apple developer communities for extensive documentation and tools.

---

**Happy Assembly Programming!** 🚀

Remember: Assembly gives you deep understanding of how computers work. Even if you don't write assembly daily, this knowledge makes you a better programmer in any language.

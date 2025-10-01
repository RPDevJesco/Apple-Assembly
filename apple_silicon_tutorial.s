// ============================================================================
// THE COMPLETE APPLE SILICON ASSEMBLY TUTORIAL
// ============================================================================
//
// This is a comprehensive, executable tutorial on Apple Silicon (ARM64)
// assembly programming. Every section is a working code example with
// extensive comments explaining registers, instructions, and concepts.
//
// To assemble and run:
//   as -o tutorial.o apple_silicon_tutorial.s
//   ld -o tutorial tutorial.o -lSystem -syslibroot `xcrun -sdk macosx --show-sdk-path` -e _main -arch arm64
//   ./tutorial
//
// Author: Tutorial for learning Apple Silicon Assembly
// Architecture: ARM64 (ARMv8-A)
// ============================================================================

.global _main
.align 2

// ============================================================================
// SECTION 1: INTRODUCTION TO ARM64 ARCHITECTURE
// ============================================================================
//
// Apple Silicon uses ARM64, which is a RISC (Reduced Instruction Set Computer)
// architecture. Key differences from x86-64:
//
// 1. FIXED INSTRUCTION WIDTH: All instructions are exactly 32 bits (4 bytes)
//    - This makes decoding faster and more predictable
//    - No variable-length instructions like x86
//
// 2. LOAD-STORE ARCHITECTURE: Only load/store instructions access memory
//    - You can't do "add rax, [rbx]" like in x86
//    - Must load to register, operate, then store back
//
// 3. MANY REGISTERS: 31 general-purpose registers (X0-X30) plus special ones
//    - x86-64 has only 16 general-purpose registers
//    - More registers = fewer memory accesses = faster code
//
// 4. SIMPLER INSTRUCTIONS: Each instruction does less, but executes faster
//    - Pipeline is more efficient
//    - Easier for CPU to predict and optimize
//
// ============================================================================

// ============================================================================
// SECTION 2: UNDERSTANDING REGISTERS - THE HEART OF THE CPU
// ============================================================================
//
// Registers are ultra-fast storage locations inside the CPU. Think of them
// as variables that live in the processor itself, not in RAM.
//
// GENERAL PURPOSE REGISTERS (GPRs):
// ----------------------------------
// ARM64 has 31 general-purpose registers: X0 through X30
//
// Each register can be accessed in two ways:
//   Xn  = Full 64-bit register (0-63 bits)
//   Wn  = Lower 32 bits only (0-31 bits)
//
// Visual representation:
//   X0: [00000000|00000000|00000000|00000000|00000000|00000000|00000000|00000000]
//        ← 32 high bits (cleared when using W0) → ← 32 low bits (W0) →
//
// CRITICAL: Writing to W0 ZEROS the upper 32 bits of X0!
//
// Example:
//   mov x0, #-1        // X0 = 0xFFFFFFFFFFFFFFFF (all bits set)
//   mov w0, #5         // X0 = 0x0000000000000005 (upper 32 bits cleared!)
//
// WHY TWO SIZES?
//   - 32-bit operations are faster and use less power
//   - Many programs don't need full 64-bit values
//   - Compatibility with 32-bit ARM code
//
// REGISTER CALLING CONVENTION (ABI):
// -----------------------------------
// These rules determine how functions use registers. Following them ensures
// your code works with libraries and other functions.
//
// X0-X7:    Function arguments and return values
//           - First 8 arguments go in these registers
//           - Additional arguments go on the stack
//           - Return value comes back in X0 (X1 for 128-bit returns)
//           - CALLER-SAVED: You can freely modify these
//
// X8:       Indirect result location
//           - Used when returning large structures
//           - Points to memory where result should be stored
//
// X9-X15:   Temporary registers
//           - CALLER-SAVED: Use freely, but don't expect them preserved across calls
//
// X16-X17:  Intra-procedure call scratch registers (IP0, IP1)
//           - Used by linker and dynamic loader
//           - Can be corrupted by function calls
//           - Don't use for values that must survive across calls
//
// X18:      Platform register (reserved by Apple)
//           - DON'T USE THIS REGISTER
//           - Reserved for future OS use
//
// X19-X28:  Callee-saved registers
//           - MUST PRESERVE: If you use these in your function, save them first!
//           - Restore them before returning
//           - Caller can rely on these being unchanged
//
// X29:      Frame Pointer (FP)
//           - Points to current function's stack frame
//           - Used for debugging and stack unwinding
//           - MUST PRESERVE
//
// X30:      Link Register (LR)
//           - Stores return address when you call a function
//           - The 'bl' instruction puts return address here
//           - The 'ret' instruction jumps to this address
//
// SP:       Stack Pointer
//           - Points to top of stack
//           - MUST stay 16-byte aligned on ARM64!
//           - Grows downward (toward lower addresses)
//
// XZR/WZR:  Zero Register
//           - Reading always returns 0
//           - Writing discards the value
//           - Useful for comparisons and clearing memory
//
// PC:       Program Counter
//           - Points to current instruction being executed
//           - Can't be directly modified (use branch instructions)
//           - Automatically increments by 4 for each instruction
//
// ============================================================================

_main:
    // ========================================================================
    // FUNCTION PROLOGUE - Setting up the stack frame
    // ========================================================================
    //
    // Every function starts with a prologue that:
    // 1. Saves the frame pointer (X29) and return address (X30)
    // 2. Sets up a new frame pointer
    // 3. Allocates stack space for local variables
    //
    // WHY?
    // - Allows debuggers to trace back through function calls
    // - Provides a stable reference point for accessing local variables
    // - Preserves the return address so we can return to caller
    //
    // The instruction 'stp' means "Store Pair" - stores two registers at once
    // The '!' means pre-increment mode: adjust SP first, then store
    //
    stp     x29, x30, [sp, #-16]!   // Save FP and LR, allocate 16 bytes
    mov     x29, sp                  // Set frame pointer to current stack pointer

    // Now we have a stack frame:
    //   [sp + 0]  = old x29 (previous frame pointer)
    //   [sp + 8]  = old x30 (return address)
    //   x29       = sp (our frame pointer)

    // ========================================================================
    // SECTION 3: BASIC DATA MOVEMENT AND IMMEDIATE VALUES
    // ========================================================================
    //
    // The MOV instruction moves data between registers or loads immediate values
    //
    // mov Xd, Xn      - Copy register Xn to Xd
    // mov Xd, #imm    - Load immediate value into Xd
    //
    // IMMEDIATE VALUES:
    // -----------------
    // An immediate is a constant value encoded directly in the instruction.
    // Since instructions are 32 bits, immediates are limited in size.
    //
    // For MOV, you can use:
    // - 16-bit values that can be shifted by 0, 16, 32, or 48 bits
    // - This allows most common constants
    //
    // For larger values, use:
    // - movz (move with zero) - loads 16 bits, zeros others
    // - movk (move with keep) - loads 16 bits, keeps others
    // - movn (move with not) - loads inverted 16 bits
    //

    mov     x0, #42                  // X0 = 42 (simple immediate)
    movz    x1, #0x1234, lsl #0      // X1 = 0x1234 (hex immediate)
    mov     x2, x0                   // X2 = X0 (register copy)

    // For larger values, use movz + movk
    movz    x3, #0x5678, lsl #0      // X3 = 0x5678 (bits 0-15)
    movk    x3, #0x1234, lsl #16     // X3 = 0x12345678 (add bits 16-31)
    movk    x3, #0xABCD, lsl #32     // X3 = 0xABCD12345678 (add bits 32-47)
    movk    x3, #0xEF01, lsl #48     // X3 = 0xEF01ABCD12345678 (add bits 48-63)

    // Using the zero register
    mov     x4, xzr                  // X4 = 0
    mov     w5, wzr                  // W5 = 0 (32-bit)

    // ========================================================================
    // SECTION 4: ARITHMETIC OPERATIONS
    // ========================================================================
    //
    // ARM64 provides rich arithmetic instructions. Most have variants:
    // - Basic version: does operation, doesn't affect flags
    // - 'S' suffix version: does operation AND sets condition flags
    //
    // CONDITION FLAGS (stored in NZCV register):
    //   N (Negative) - Set if result is negative (bit 63 = 1 for 64-bit)
    //   Z (Zero)     - Set if result is zero
    //   C (Carry)    - Set if unsigned overflow/carry out
    //   V (oVerflow) - Set if signed overflow
    //

    // ADDITION
    // --------
    mov     x0, #10
    mov     x1, #20
    add     x2, x0, x1               // x2 = x0 + x1 = 30 (no flags)
    adds    x3, x0, x1               // x3 = x0 + x1 = 30 (sets flags)

    // Addition with immediate
    add     x4, x0, #5               // x4 = x0 + 5 = 15

    // Addition with carry (for multi-precision arithmetic)
    mov     x5, #0xFFFFFFFFFFFFFFFF  // Max 64-bit value
    mov     x6, #1
    adds    x7, x5, x6               // x7 = 0, Carry flag SET
    adc     x8, xzr, xzr             // x8 = 0 + 0 + carry = 1

    // SUBTRACTION
    // -----------
    mov     x0, #100
    mov     x1, #30
    sub     x2, x0, x1               // x2 = 100 - 30 = 70
    subs    x3, x0, x1               // x3 = 70, sets flags

    // Reverse subtraction (useful in some algorithms)
    mov     x4, #10
    mov     x5, #50
    // rsb would be: x4 = x5 - x4, but ARM64 removed it
    // Instead: sub x4, x5, x4
    sub     x4, x5, x4               // x4 = 50 - 10 = 40

    // Negation (two's complement)
    mov     x6, #42
    neg     x7, x6                   // x7 = -42

    // MULTIPLICATION
    // --------------
    // ARM64 has hardware multiply (unlike older ARM)
    //
    mov     x0, #6
    mov     x1, #7
    mul     x2, x0, x1               // x2 = 6 * 7 = 42

    // For signed multiplication with full result:
    smull   x3, w0, w1               // x3 = (signed)w0 * w1 (64-bit result)

    // For unsigned multiplication with full result:
    umull   x4, w0, w1               // x4 = (unsigned)w0 * w1

    // High word of multiplication
    smulh   x5, x0, x1               // x5 = high 64 bits of x0 * x1

    // Multiply-accumulate (fused, faster than separate mul+add)
    mov     x6, #100                 // accumulator
    madd    x7, x0, x1, x6           // x7 = (x0 * x1) + x6 = 42 + 100 = 142

    // Multiply-subtract
    msub    x8, x0, x1, x6           // x8 = x6 - (x0 * x1) = 100 - 42 = 58

    // DIVISION
    // --------
    // ARM64 has native division! (This is relatively rare in RISC CPUs)
    //
    mov     x0, #100
    mov     x1, #3
    sdiv    x2, x0, x1               // x2 = 100 / 3 = 33 (signed)
    udiv    x3, x0, x1               // x3 = 100 / 3 = 33 (unsigned)

    // Computing modulo (no direct instruction)
    // Formula: x % y = x - (x/y) * y
    udiv    x4, x0, x1               // x4 = 100 / 3 = 33
    msub    x5, x4, x1, x0           // x5 = 100 - (33 * 3) = 1
    // So 100 % 3 = 1

    // ========================================================================
    // SECTION 5: LOGICAL OPERATIONS AND BIT MANIPULATION
    // ========================================================================
    //
    // Logical operations work on individual bits
    //

    // BITWISE AND
    mov     x0, #0b11110000          // Binary literal
    mov     x1, #0b10101010
    and     x2, x0, x1               // x2 = 0b10100000

    // BITWISE OR
    orr     x3, x0, x1               // x3 = 0b11111010

    // BITWISE XOR (exclusive or)
    eor     x4, x0, x1               // x4 = 0b01011010

    // BITWISE NOT
    mvn     x5, x0                   // x5 = ~x0 (all bits flipped)

    // BIT CLEAR (AND with NOT)
    bic     x6, x0, x1               // x6 = x0 & ~x1

    // TEST (AND but only set flags, don't store)
    tst     x0, #0b10000000          // Test if bit 7 is set
    // Z flag will be 0 if bit was set, 1 if bit was clear

    // SHIFTS
    // ------
    // Shifts move bits left or right
    //
    mov     x0, #0b00001111

    // Logical Shift Left (LSL) - shift left, fill with zeros
    lsl     x1, x0, #2               // x1 = 0b00111100 (multiply by 4)

    // Logical Shift Right (LSR) - shift right, fill with zeros
    lsr     x2, x0, #2               // x2 = 0b00000011 (unsigned divide by 4)

    // Arithmetic Shift Right (ASR) - shift right, fill with sign bit
    mov     x3, #-16                 // Negative number
    asr     x4, x3, #2               // x4 = -4 (preserves sign)

    // Rotate Right (ROR) - bits wrap around
    mov     x5, #0b10000001
    ror     x6, x5, #1               // x6 = 0b11000000... (bit 0 -> bit 63)

    // Variable shift (shift amount in register)
    mov     x7, #3
    lsl     x8, x0, x7               // x8 = x0 << 3

    // BIT FIELD OPERATIONS
    // --------------------
    // Extract and manipulate specific bit ranges
    //
    movz    x0, #0x5678, lsl #0      // Load lower 16 bits
    movk    x0, #0x1234, lsl #16     // Add upper 16 bits

    // Unsigned Bit Field Extract (UBFX)
    // Extract bits [16:23] (8 bits starting at bit 16)
    ubfx    x1, x0, #16, #8          // x1 = 0x34

    // Signed Bit Field Extract (SBFX)
    // Like UBFX but sign-extends
    mov     x2, #0xFFFF0000
    sbfx    x3, x2, #16, #8          // x3 = 0xFFFFFFFFFFFFFFFF (sign extended)

    // Bit Field Insert (BFI)
    // Insert bits into specific position
    mov     x4, #0xFFFFFFFFFFFFFFFF
    mov     x5, #0x42
    bfi     x4, x5, #8, #8           // Insert x5[0:7] into x4[8:15]

    // Count Leading Zeros (CLZ)
    mov     x6, #0x00000000FFFFFFFF
    clz     x7, x6                   // x7 = 32 (32 leading zeros)

    // Reverse Bits
    mov     x8, #0x0F                // 0b00001111
    rbit    x9, x8                   // x9 = 0xF000... (bits reversed)

    // Reverse Bytes (endian swap)
    movz    x10, #0xCDEF, lsl #0     // Build the value piece by piece
    movk    x10, #0x90AB, lsl #16
    movk    x10, #0x5678, lsl #32
    movk    x10, #0x1234, lsl #48    // x10 = 0x1234567890ABCDEF
    rev     x11, x10                 // x11 = 0xEFCDAB9078563412

    // ========================================================================
    // SECTION 6: MEMORY OPERATIONS - THE LOAD-STORE ARCHITECTURE
    // ========================================================================
    //
    // In ARM64, ONLY load and store instructions can access memory.
    // You cannot do arithmetic directly on memory like "add x0, [x1]" (as in x86).
    //
    // MEMORY HIERARCHY:
    //   Registers:  ~0 cycles (instant)
    //   L1 Cache:   ~4 cycles
    //   L2 Cache:   ~12 cycles
    //   L3 Cache:   ~40 cycles
    //   RAM:        ~100-200 cycles
    //
    // This is why keeping data in registers is crucial for performance!
    //
    // ALIGNMENT REQUIREMENTS:
    //   - Bytes (8-bit):        No alignment needed
    //   - Halfwords (16-bit):   Must be 2-byte aligned (address % 2 == 0)
    //   - Words (32-bit):       Must be 4-byte aligned (address % 4 == 0)
    //   - Doublewords (64-bit): Must be 8-byte aligned (address % 8 == 0)
    //   - Quadwords (128-bit):  Must be 16-byte aligned (address % 16 == 0)
    //
    // Unaligned access causes performance penalty or crashes!
    //

    // Allocate some stack space for examples
    sub     sp, sp, #64              // Allocate 64 bytes (must be multiple of 16)

    // BASIC LOAD INSTRUCTIONS
    // -----------------------

    // Store some test data
    movz    x0, #0xDEF0, lsl #0      // Build 0x123456789ABCDEF0
    movk    x0, #0x9ABC, lsl #16
    movk    x0, #0x5678, lsl #32
    movk    x0, #0x1234, lsl #48
    str     x0, [sp, #0]             // Store 64-bit value to stack

    // Load 64-bit (LDR = LoaD Register)
    ldr     x1, [sp, #0]             // x1 = 0x123456789ABCDEF0

    // Load 32-bit (zero-extends to 64-bit)
    ldr     w2, [sp, #0]             // w2 = 0x9ABCDEF0, x2 = 0x000000009ABCDEF0

    // Load 32-bit with sign extension
    mov     x3, #0xFFFFFFFF
    str     w3, [sp, #8]
    ldrsw   x4, [sp, #8]             // x4 = 0xFFFFFFFFFFFFFFFF (sign extended)

    // Load 16-bit halfword (LDRH)
    ldrh    w5, [sp, #0]             // w5 = 0xDEF0 (lower 16 bits)

    // Load 16-bit with sign extension
    ldrsh   w6, [sp, #0]             // Sign extend 16-bit to 32-bit

    // Load 8-bit byte (LDRB)
    ldrb    w7, [sp, #0]             // w7 = 0xF0 (lowest byte)

    // Load 8-bit with sign extension
    ldrsb   w8, [sp, #0]             // Sign extend 8-bit to 32-bit

    // BASIC STORE INSTRUCTIONS
    // ------------------------

    movz    x0, #0x7788, lsl #0      // Build 0x1122334455667788
    movk    x0, #0x5566, lsl #16
    movk    x0, #0x3344, lsl #32
    movk    x0, #0x1122, lsl #48
    str     x0, [sp, #16]            // Store 64-bit
    str     w0, [sp, #24]            // Store 32-bit (lower half only)
    strh    w0, [sp, #28]            // Store 16-bit (lower 2 bytes)
    strb    w0, [sp, #30]            // Store 8-bit (lowest byte)

    // ADDRESSING MODES
    // ----------------
    // ARM64 has rich addressing modes for flexible memory access
    //

    // 1. BASE REGISTER ONLY
    //    Address = [Xn]
    mov     x0, sp
    ldr     x1, [x0]                 // Load from address in x0

    // 2. BASE + IMMEDIATE OFFSET
    //    Address = [Xn, #offset]
    ldr     x2, [sp, #8]             // Load from sp + 8

    // 3. BASE + REGISTER OFFSET
    //    Address = [Xn, Xm]
    mov     x3, #16
    ldr     x4, [sp, x3]             // Load from sp + x3

    // 4. BASE + SHIFTED REGISTER
    //    Address = [Xn, Xm, LSL #shift]
    mov     x5, #2                   // Index
    ldr     x6, [sp, x5, lsl #3]     // Load from sp + (x5 << 3) = sp + 16

    // 5. PRE-INDEXED
    //    Update base register BEFORE access
    //    Address = [Xn, #offset]!
    mov     x7, sp
    ldr     x8, [x7, #8]!            // x7 = x7 + 8, then load from x7

    // 6. POST-INDEXED
    //    Update base register AFTER access
    //    Address = [Xn], #offset
    mov     x9, sp
    ldr     x10, [x9], #8            // Load from x9, then x9 = x9 + 8

    // LOAD/STORE PAIRS
    // ----------------
    // Efficiently load/store two registers at once
    // Improves performance by reducing instruction count
    //
    mov     x0, #0x1111
    mov     x1, #0x2222
    stp     x0, x1, [sp, #32]        // Store pair: x0 to [sp+32], x1 to [sp+40]

    ldp     x2, x3, [sp, #32]        // Load pair: x2 from [sp+32], x3 from [sp+40]

    // Load/store pair with writeback
    stp     x0, x1, [sp, #-16]!      // Pre-decrement: sp -= 16, then store
    ldp     x4, x5, [sp], #16        // Post-increment: load, then sp += 16

    // Restore stack
    add     sp, sp, #64

    // ========================================================================
    // SECTION 7: CONTROL FLOW - BRANCHES AND JUMPS
    // ========================================================================
    //
    // Control flow determines the order in which instructions execute.
    // Without branches, programs would be purely sequential!
    //
    // UNCONDITIONAL BRANCHES
    // ----------------------
    //

    // B - Branch (direct jump)
    // Changes PC to target address
    // b       target_label

    // BR - Branch to Register
    // Jumps to address in register
    // adr     x0, some_label
    // br      x0

    // BL - Branch with Link (function call)
    // Saves return address in X30 (LR), then jumps
    bl      demo_function_calls     // Call a function

    // BLR - Branch with Link to Register
    // Like BL but target is in register
    // adr     x0, my_function
    // blr     x0

    // RET - Return from function
    // Jumps to address in X30 (or specified register)
    // ret                          // Jump to X30
    // ret     x0                   // Jump to address in X0

    // CONDITIONAL BRANCHES
    // --------------------
    // These depend on CONDITION FLAGS (N, Z, C, V)
    //
    // First, set flags with a comparison:
    mov     x0, #5
    mov     x1, #10
    cmp     x0, x1                   // Sets flags based on x0 - x1

    // Now branch based on flags:
    b.eq    branch_equal             // Branch if equal (Z flag set)
    b.ne    branch_not_equal         // Branch if not equal (Z flag clear)
    b.lt    branch_less              // Branch if less than (signed)
    b.le    branch_less_equal        // Branch if less or equal (signed)
    b.gt    branch_greater           // Branch if greater than (signed)
    b.ge    branch_greater_equal     // Branch if greater or equal (signed)

    // For unsigned comparisons:
    b.lo    branch_lower             // Branch if lower (unsigned <)
    b.ls    branch_lower_same        // Branch if lower or same (unsigned <=)
    b.hi    branch_higher            // Branch if higher (unsigned >)
    b.hs    branch_higher_same       // Branch if higher or same (unsigned >=)

    // COMPARE AND BRANCH INSTRUCTIONS
    // -------------------------------
    // These combine compare and branch in one instruction (faster!)
    //
    mov     x0, #0
    cbz     x0, branch_if_zero       // Branch if x0 == 0
    cbnz    x0, branch_if_not_zero   // Branch if x0 != 0

    // TEST BIT AND BRANCH
    // -------------------
    // Branch based on a single bit
    //
    mov     x0, #0b10000000
    tbz     x0, #7, branch_bit_clear // Branch if bit 7 is 0
    tbnz    x0, #7, branch_bit_set   // Branch if bit 7 is 1

branch_equal:
branch_not_equal:
branch_less:
branch_less_equal:
branch_greater:
branch_greater_equal:
branch_lower:
branch_lower_same:
branch_higher:
branch_higher_same:
branch_if_zero:
branch_if_not_zero:
branch_bit_clear:
branch_bit_set:
    nop                              // No operation (placeholder)

    // ========================================================================
    // SECTION 8: CONDITION FLAGS IN DETAIL
    // ========================================================================
    //
    // The NZCV register holds 4 condition flags that control branches:
    //
    // N (Negative):  Set if result is negative (bit 63 = 1)
    // Z (Zero):      Set if result is zero
    // C (Carry):     Set if unsigned overflow/carry occurred
    // V (oVerflow):  Set if signed overflow occurred
    //
    // FLAGS ARE SET BY:
    // - Instructions with 'S' suffix: ADDS, SUBS, ANDS, etc.
    // - Compare instructions: CMP, CMN, TST
    //

    // Example 1: Unsigned overflow detection
    mov     x0, #0xFFFFFFFFFFFFFFFF  // Max unsigned value
    mov     x1, #1
    adds    x2, x0, x1               // x2 = 0, Carry flag SET
    b.cs    carry_was_set            // Branch if carry set (overflow occurred)

carry_was_set:

    // Example 2: Signed overflow detection
    mov     x3, #0x7FFFFFFFFFFFFFFF  // Max positive signed value
    mov     x4, #1
    adds    x5, x3, x4               // x5 = negative! Overflow flag SET
    b.vs    overflow_occurred        // Branch if overflow set

overflow_occurred:

    // Example 3: Zero flag
    mov     x6, #100
    subs    x7, x6, #100             // x7 = 0, Zero flag SET
    b.eq    was_equal                // b.eq checks Zero flag

was_equal:

    // CONDITIONAL SELECT INSTRUCTIONS
    // -------------------------------
    // These avoid branches, which is faster on modern CPUs!
    //
    mov     x0, #10
    mov     x1, #20
    cmp     x0, x1                   // Compare

    // Select based on condition (no branch!)
    mov     x2, #100
    mov     x3, #200
    csel    x4, x2, x3, lt           // x4 = (x0 < x1) ? x2 : x3

    // Conditional increment
    csinc   x5, x2, x3, eq           // x5 = (equal) ? x2 : x3 + 1

    // Conditional invert
    csinv   x6, x2, x3, gt           // x6 = (greater) ? x2 : ~x3

    // Conditional set (set to 1 or 0 based on condition)
    cmp     x0, #5
    cset    x7, gt                   // x7 = (x0 > 5) ? 1 : 0

    // ========================================================================
    // SECTION 9: FLOATING POINT AND SIMD OPERATIONS
    // ========================================================================
    //
    // ARM64 has 32 SIMD/Floating-Point registers: V0-V31
    //
    // Each can be accessed at different widths:
    //   Bn  - 8 bits  (byte)
    //   Hn  - 16 bits (half-precision float)
    //   Sn  - 32 bits (single-precision float)
    //   Dn  - 64 bits (double-precision float)
    //   Qn  - 128 bits (vector/SIMD operations)
    //

    // FLOATING POINT BASICS
    // ---------------------

    // Move float immediate to register
    fmov    d0, #1.0                 // d0 = 1.0 (double)
    fmov    s1, #2.5                 // s1 = 2.5 (float)

    // Move between general and FP registers
    mov     x0, #0x4014000000000000  // Bit pattern for 5.0
    fmov    d2, x0                   // d2 = 5.0
    fmov    x1, d2                   // x1 = bit pattern of d2

    // Floating point arithmetic
    fmov    d3, #3.0
    fmov    d4, #4.0
    fadd    d5, d3, d4               // d5 = 3.0 + 4.0 = 7.0
    fsub    d6, d4, d3               // d6 = 4.0 - 3.0 = 1.0
    fmul    d7, d3, d4               // d7 = 3.0 * 4.0 = 12.0
    fdiv    d8, d7, d3               // d8 = 12.0 / 3.0 = 4.0

    // Fused multiply-add (more accurate and faster!)
    fmadd   d9, d3, d4, d5           // d9 = (3.0 * 4.0) + 7.0 = 19.0
    fmsub   d10, d3, d4, d5          // d10 = (3.0 * 4.0) - 7.0 = 5.0

    // Square root
    fmov    d11, #16.0
    fsqrt   d12, d11                 // d12 = sqrt(16.0) = 4.0

    // Absolute value and negate
    fmov    d13, #-5.5
    fabs    d14, d13                 // d14 = 5.5
    fneg    d15, d13                 // d15 = 5.5

    // Min and Max
    fmov    d16, #10.0
    fmov    d17, #20.0
    fmax    d18, d16, d17            // d18 = 20.0
    fmin    d19, d16, d17            // d19 = 10.0

    // Rounding
    // Create 3.7 using integer and convert
    mov     w0, #37                  // 37
    ucvtf   d20, w0                  // d20 = 37.0
    fmov    d30, #10.0
    fdiv    d20, d20, d30            // d20 = 3.7
    frintn  d21, d20                 // d21 = 4.0 (round to nearest)
    frintp  d22, d20                 // d22 = 4.0 (round toward +inf)
    frintm  d23, d20                 // d23 = 3.0 (round toward -inf)
    frintz  d24, d20                 // d24 = 3.0 (round toward zero)

    // Floating point compare
    fmov    d25, #5.0
    fmov    d26, #10.0
    fcmp    d25, d26                 // Sets flags like integer CMP
    b.lt    fp_less_than             // Branch if 5.0 < 10.0

fp_less_than:

    // Convert between integer and float
    mov     x2, #42
    scvtf   d27, x2                  // d27 = 42.0 (signed int to float)
    ucvtf   d28, x2                  // d28 = 42.0 (unsigned int to float)

    // Create 7.8 by dividing 78 / 10
    mov     w0, #78
    ucvtf   d29, w0                  // d29 = 78.0
    fmov    d31, #10.0
    fdiv    d29, d29, d31            // d29 = 7.8
    fcvtzs  x3, d29                  // x3 = 7 (float to signed int, truncate)
    fcvtzu  x4, d29                  // x4 = 7 (float to unsigned int)

    // NEON / SIMD OPERATIONS
    // ----------------------
    // Process multiple values in parallel!
    //
    // Vector notation: Vn.T where T is:
    //   8B  - 8 bytes (8-bit values)
    //   16B - 16 bytes
    //   4H  - 4 halfwords (16-bit)
    //   8H  - 8 halfwords
    //   2S  - 2 singles (32-bit)
    //   4S  - 4 singles
    //   2D  - 2 doubles (64-bit)
    //

    // Example: Add 4 integers in parallel
    // Load data into vectors (in real code, load from memory)
    mov     x5, #1
    dup     v0.4s, w5                // v0 = [1, 1, 1, 1]
    mov     x6, #2
    dup     v1.4s, w6                // v1 = [2, 2, 2, 2]

    add     v2.4s, v0.4s, v1.4s      // v2 = [3, 3, 3, 3] (4 adds in parallel!)

    // Multiply vectors
    mul     v3.4s, v0.4s, v1.4s      // v3 = [2, 2, 2, 2]

    // Max/Min across vectors
    smax    v4.4s, v0.4s, v1.4s      // Element-wise maximum

    // Floating point SIMD
    fmov    v5.4s, #1.0              // v5 = [1.0, 1.0, 1.0, 1.0]
    fmov    v6.4s, #2.0              // v6 = [2.0, 2.0, 2.0, 2.0]
    fadd    v7.4s, v5.4s, v6.4s      // v7 = [3.0, 3.0, 3.0, 3.0]

    // Horizontal operations (across vector)
    fmaxv   s8, v7.4s                // s8 = max(v7[0], v7[1], v7[2], v7[3])

    // ========================================================================
    // SECTION 10: PRACTICAL EXAMPLE - STRING LENGTH
    // ========================================================================
    //
    // Let's implement strlen() to show practical assembly
    //
    adrp    x0, test_string@PAGE     // Load address of test string
    add     x0, x0, test_string@PAGEOFF
    bl      strlen_asm               // Call our strlen
    // Result in x0

    // ========================================================================
    // SECTION 11: PRACTICAL EXAMPLE - FIBONACCI
    // ========================================================================

    mov     x0, #10                  // Calculate fibonacci(10)
    bl      fibonacci                // Call fibonacci function
    // Result in x0

    // ========================================================================
    // SECTION 12: PRACTICAL EXAMPLE - ARRAY SUM WITH SIMD
    // ========================================================================

    adrp    x0, test_array@PAGE      // Array address
    add     x0, x0, test_array@PAGEOFF
    mov     x1, #8                   // Array length
    bl      array_sum_simd           // Call SIMD sum
    // Result in x0

    // ========================================================================
    // SECTION 13: SYSTEM CALLS - INTERACTING WITH THE OS
    // ========================================================================
    //
    // System calls let your program interact with the operating system.
    // On macOS, you use the BSD syscall interface.
    //
    // HOW TO MAKE A SYSCALL:
    // 1. Put syscall number in X16 (NOT X0 like Linux!)
    // 2. Put arguments in X0-X7
    // 3. Execute SVC #0x80 (Supervisor Call)
    // 4. Result comes back in X0
    // 5. Carry flag indicates error if set
    //
    // Common syscall numbers:
    //   1  = exit(int status)
    //   3  = read(int fd, void *buf, size_t count)
    //   4  = write(int fd, const void *buf, size_t count)
    //   5  = open(const char *path, int flags, mode_t mode)
    //   6  = close(int fd)
    //   20 = getpid(void)
    //

    // Print "Hello, World!\n" to stdout
    mov     x16, #4                  // Syscall number for write
    mov     x0, #1                   // File descriptor 1 = stdout
    adrp    x1, hello_msg@PAGE       // Buffer address
    add     x1, x1, hello_msg@PAGEOFF
    mov     x2, #14                  // Number of bytes to write
    svc     #0x80                    // Make the system call

    // ========================================================================
    // FUNCTION EPILOGUE AND EXIT
    // ========================================================================

    // Exit program with status 0
    mov     x16, #1                  // Syscall number for exit
    mov     x0, #0                   // Exit status = 0 (success)
    svc     #0x80                    // Make syscall (will not return)

    // Normally we would restore and return:
    // mov     sp, x29                  // Restore stack pointer
    // ldp     x29, x30, [sp], #16      // Restore FP and LR
    // ret                              // Return to caller
    // But exit() never returns, so we don't reach here

// ============================================================================
// HELPER FUNCTIONS - Practical examples of assembly functions
// ============================================================================

// ----------------------------------------------------------------------------
// demo_function_calls - Shows how function calls work
// ----------------------------------------------------------------------------
demo_function_calls:
    // Prologue
    stp     x29, x30, [sp, #-32]!    // Save FP and LR, allocate 32 bytes
    mov     x29, sp                  // Set frame pointer
    stp     x19, x20, [sp, #16]      // Save callee-saved registers

    // When we call a function:
    // 1. Arguments go in X0-X7 (additional args on stack)
    // 2. BL instruction saves return address in X30
    // 3. Function executes
    // 4. Return value comes back in X0
    // 5. RET instruction jumps back to address in X30

    mov     x0, #5                   // First argument
    mov     x1, #10                  // Second argument
    bl      add_two_numbers          // Call function
    mov     x19, x0                  // Save result

    // Epilogue
    ldp     x19, x20, [sp, #16]      // Restore callee-saved registers
    ldp     x29, x30, [sp], #32      // Restore FP and LR
    ret

// ----------------------------------------------------------------------------
// add_two_numbers - Simple function that adds two numbers
// Parameters: x0 = first number, x1 = second number
// Returns: x0 = sum
// ----------------------------------------------------------------------------
add_two_numbers:
    // This function is so simple it doesn't need a stack frame
    add     x0, x0, x1               // x0 = x0 + x1
    ret                              // Return with result in x0

// ----------------------------------------------------------------------------
// strlen_asm - Calculate length of null-terminated string
// Parameters: x0 = pointer to string
// Returns: x0 = length (not including null terminator)
// ----------------------------------------------------------------------------
strlen_asm:
    // Algorithm:
    // 1. Start counter at 0
    // 2. Load byte from string
    // 3. If byte is 0 (null terminator), return counter
    // 4. Otherwise increment counter and repeat

    mov     x1, #0                   // Counter = 0

strlen_loop:
    ldrb    w2, [x0, x1]             // Load byte at string[counter]
    cbz     w2, strlen_done          // If byte is 0, we're done
    add     x1, x1, #1               // Increment counter
    b       strlen_loop              // Continue loop

strlen_done:
    mov     x0, x1                   // Return count in x0
    ret

// ----------------------------------------------------------------------------
// fibonacci - Calculate fibonacci number recursively
// Parameters: x0 = n (which fibonacci number to calculate)
// Returns: x0 = fibonacci(n)
//
// Fibonacci sequence: 0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, ...
// Formula: fib(n) = fib(n-1) + fib(n-2)
// Base cases: fib(0) = 0, fib(1) = 1
// ----------------------------------------------------------------------------
fibonacci:
    // Prologue
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    str     x19, [sp, #16]           // Save x19 (callee-saved)

    // Base case: if n <= 1, return n
    cmp     x0, #1
    b.le    fib_base_case

    // Recursive case: fib(n-1) + fib(n-2)
    mov     x19, x0                  // Save n

    sub     x0, x0, #1               // n - 1
    bl      fibonacci                // fib(n-1)
    mov     x20, x0                  // Save fib(n-1) result

    sub     x0, x19, #2              // n - 2
    bl      fibonacci                // fib(n-2)

    add     x0, x20, x0              // fib(n-1) + fib(n-2)
    b       fib_done

fib_base_case:
    // n is 0 or 1, just return it
    // (x0 already contains n)

fib_done:
    // Epilogue
    ldr     x19, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

// ----------------------------------------------------------------------------
// array_sum_simd - Sum array of integers using SIMD
// Parameters: x0 = pointer to array, x1 = number of elements
// Returns: x0 = sum of all elements
//
// This demonstrates NEON SIMD to process 4 integers at once
// ----------------------------------------------------------------------------
array_sum_simd:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    // Initialize accumulator to zero
    movi    v0.4s, #0                // v0 = [0, 0, 0, 0]

    // Process 4 elements at a time
    mov     x2, #0                   // Index counter

array_sum_loop:
    // Check if we have at least 4 elements left
    add     x3, x2, #4
    cmp     x3, x1
    b.gt    array_sum_remainder      // If less than 4 left, handle individually

    // Load 4 integers (16 bytes)
    lsl     x4, x2, #2               // x4 = index * 4 (byte offset)
    add     x4, x0, x4               // x4 = array + offset
    ld1     {v1.4s}, [x4]            // Load 4 ints into v1

    // Add to accumulator
    add     v0.4s, v0.4s, v1.4s      // v0 += v1 (4 adds in parallel!)

    add     x2, x2, #4               // index += 4
    b       array_sum_loop

array_sum_remainder:
    // Handle remaining elements (less than 4)
    cmp     x2, x1
    b.ge    array_sum_reduce

    lsl     x4, x2, #2               // Byte offset
    ldr     w3, [x0, x4]             // Load one int

    // Add to first lane of accumulator
    mov     w4, v0.s[0]              // Extract first element
    add     w4, w4, w3               // Add
    mov     v0.s[0], w4              // Put back

    add     x2, x2, #1
    b       array_sum_remainder

array_sum_reduce:
    // Now v0 has [sum0, sum1, sum2, sum3]
    // We need to add them together

    // Add pairs: [sum0+sum1, sum2+sum3, ?, ?]
    addp    v0.4s, v0.4s, v0.4s

    // Add pairs again: [sum0+sum1+sum2+sum3, ?, ?, ?]
    addp    v0.4s, v0.4s, v0.4s

    // Extract final sum to x0
    umov    w0, v0.s[0]

    ldp     x29, x30, [sp], #16
    ret

// ============================================================================
// DATA SECTION - Constants and initialized data
// ============================================================================

.data
.align 3                             // Align to 8-byte boundary

hello_msg:
    .ascii "Hello, World!\n"

test_string:
    .asciz "Assembly is awesome!"   // .asciz adds null terminator

test_array:
    .word 1, 2, 3, 4, 5, 6, 7, 8     // Array of 32-bit integers

// ============================================================================
// END OF TUTORIAL
// ============================================================================
//
// CONGRATULATIONS! You've completed the Apple Silicon Assembly tutorial!
//
// You've learned:
// ✓ ARM64 architecture fundamentals
// ✓ All register types and their purposes
// ✓ Data movement and immediate values
// ✓ Arithmetic and logical operations
// ✓ Bit manipulation techniques
// ✓ Memory operations and addressing modes
// ✓ Control flow and branching
// ✓ Condition flags in detail
// ✓ Floating point operations
// ✓ SIMD/NEON parallel processing
// ✓ Function calling conventions
// ✓ System calls for OS interaction
// ✓ Practical examples (strlen, fibonacci, SIMD sum)
//
// NEXT STEPS:
// -----------
// 1. Assemble and run this code:
//    as -o tutorial.o apple_silicon_tutorial.s
//    ld -o tutorial tutorial.o -lSystem -syslibroot `xcrun -sdk macosx --show-sdk-path` -e _main -arch arm64
//    ./tutorial
//
// 2. Modify the examples - change values, add your own functions
//
// 3. Study real-world assembly:
//    - Use "otool -tv" to disassemble programs
//    - Use Compiler Explorer (godbolt.org) to see what C produces
//    - Debug with LLDB: "lldb ./tutorial"
//
// 4. Write performance-critical code:
//    - Image processing with NEON
//    - Cryptography primitives
//    - Math libraries
//    - Compression algorithms
//
// 5. Learn advanced topics:
//    - Apple's AMX instructions (matrix operations)
//    - Atomic operations and memory ordering
//    - Exception handling
//    - Interfacing with Objective-C runtime
//
// RESOURCES:
// ----------
// - ARM Architecture Reference Manual (official docs)
// - Apple's Developer Documentation
// - "Programming with 64-Bit ARM Assembly Language" by Stephen Smith
// - Compiler Explorer (godbolt.org) - see assembly from C
// - ARM Community Forums
//
// Remember: Assembly is about understanding HOW computers work at the lowest
// level. Even if you don't write assembly daily, knowing it makes you a
// better programmer in any language!
//
// Happy hacking! 🚀
//
// ============================================================================

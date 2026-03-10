/* start.S - Bootstrap assembly for nimos kernel */

.section .text
.global _start
.extern kmain

_start:
    /* Clear direction flag */
    cld

    /* Set up stack - use higher-half address */
    movq $stack_top, %rsp

    /* Clear frame pointer */
    xorq %rbp, %rbp

    /* Call Nim kernel main */
    call kmain

    /* If kmain returns (it shouldn't), halt */
1:
    cli
    hlt
    jmp 1b

/* ============================================================
   Keyboard IRQ1 ISR stub
   - CPU has already pushed: SS, RSP, RFLAGS, CS, RIP
   - We save all GP registers, call Nim handler, restore, iretq
   ============================================================ */
.global keyboard_isr_stub
.extern keyboardHandler
keyboard_isr_stub:
    push %rax
    push %rbx
    push %rcx
    push %rdx
    push %rsi
    push %rdi
    push %r8
    push %r9
    push %r10
    push %r11
    push %r12
    push %r13
    push %r14
    push %r15
    push %rbp

    call keyboardHandler

    pop %rbp
    pop %r15
    pop %r14
    pop %r13
    pop %r12
    pop %r11
    pop %r10
    pop %r9
    pop %r8
    pop %rdi
    pop %rsi
    pop %rdx
    pop %rcx
    pop %rbx
    pop %rax

    iretq

/* Stack space */
.section .bss
.align 16
stack_bottom:
    .skip 16384  /* 16 KB stack */
stack_top:

; x86-64 Linux (NASM)
section .data
    msg db "Hello, World!", 10

section .text
    global _start
_start:
    mov rax, 1        ; sys_write
    mov rdi, 1        ; stdout
    mov rsi, msg
    mov rdx, 14
    syscall
    mov rax, 60       ; sys_exit
    xor rdi, rdi
    syscall

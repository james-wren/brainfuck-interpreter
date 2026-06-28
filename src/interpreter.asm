section .data
    code db "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.", 0
    ; just some leftover testing data

section .bss
    tape resb 30000
    code_buf resb 65536

section .text
    global _start

_start:
    mov rax, [rsp]
    cmp rax, 2
    jl exit

    mov rdi, [rsp + 16]

    ; Opens file
    mov rax, 2
    mov rsi, 0
    syscall

    cmp rax, 0
    js exit
    mov r12, rax

    ; Read file into buffer
    mov rax, 0
    mov rdi, r12
    mov rsi, code_buf
    mov rdx, 65536
    syscall

    ; Close file
    mov rax, 3
    mov rdi, r12
    syscall

    mov rsi, code_buf
    mov rbx, tape

interpret_loop:
    mov al, [rsi]
    cmp al, 0
    je exit

    cmp al, '>'
    je move_right
    cmp al, '<'
    je move_left
    cmp al, '+'
    je increment_byte
    cmp al, '-'
    je decrement_byte
    cmp al, '.'
    je output_byte
    cmp al, ','
    je input_byte
    cmp al, '['
    je loop_start
    cmp al, ']'
    je loop_end

    jmp next_char

; Pointer munipulation
move_right:
    inc rbx
    jmp next_char

move_left:
    dec rbx
    jmp next_char

; Byte munipulation
increment_byte:
    inc byte [rbx]
    jmp next_char

decrement_byte:
    dec byte [rbx]
    jmp next_char

; I/O operations
output_byte:
    push rsi
    push rbx

    mov rax, 1 ; sys_write
    mov rdi, 1 ; stdout
    mov rsi, rbx
    mov rdx, 1
    syscall

    pop rbx
    pop rsi
    jmp next_char

input_byte:
    push rsi
    push rbx

    mov rax, 0 ; sys_read
    mov rdi, 0 ; stdin
    mov rsi, rbx
    mov rdx, 1
    syscall

    pop rbx
    pop rsi
    jmp next_char

loop_start:
    cmp byte [rbx], 0
    jne next_char

    mov rcx, 1
.skip_forward:
    inc rsi
    mov al, [rsi]

    cmp al, '['
    je .nest_in
    cmp al, ']'
    je .nest_out
    jmp .skip_forward

.nest_in:
    inc rcx
    jmp .skip_forward

.nest_out:
    dec rcx
    cmp rcx, 0
    jne .skip_forward
    jmp next_char

loop_end:
    cmp byte [rbx], 0
    je next_char

    mov rcx, 1
.skip_backward:
    dec rsi
    mov al, [rsi]

    cmp al, ']'
    je .nest_in_back
    cmp al, '['
    je .nest_out_back
    jmp .skip_backward
.nest_in_back:
    inc rcx
    jmp .skip_backward
.nest_out_back:
    dec rcx
    cmp rcx, 0
    jne .skip_backward
    jmp next_char

next_char:
    inc rsi
    jmp interpret_loop

exit:
    mov rax, 60
    mov rdi, 0
    syscall
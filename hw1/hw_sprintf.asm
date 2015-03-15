global hw_sprintf

section .text

plus_flag    equ   1 << 0
space_flag   equ   1 << 1
dash_flag    equ   1 << 2
zero_flag    equ   1 << 3
width_flag   equ   1 << 4
percent_flag equ   1 << 5

; ebp - pointer to argument int
; edi - pointer to out buffer
; use:
; eax for integer store
; edx for division
; ebx for division
; ecx for esp save state

itoa:
    ; save registers used in fucntion
    push eax
    push edx
    push ebx
    ; move argument value in eax
    mov eax, [ebp]
    ; check for signed negative value
    test eax, 0x80000000
    jne .signed_neg
    jmp .main_process
    .signed_neg:
        neg eax

    .main_process:
        ; base for division
        mov ebx, 10
        ; save old esp value for reverse
        mov ecx, esp
        dec esp
    .div_circle:
        ; clean edx for division
        xor edx, edx
        div ebx
        ; shift for character value
        ; and put
        add edx, '0'
        ; put character to stask
        ; and move pointer of esp
        mov byte [esp], dl
        dec esp
        cmp eax, 0
        jne .div_circle
        inc esp
    .reverse_circle:
        ; moves character from stask to out buffer
        mov dl, byte [esp]
        mov byte [edi], dl
        inc edi
        inc esp
        cmp esp, ecx
        jne .reverse_circle

    pop ebx
    pop edx
    pop eax
    ret

; void(char* out, char* format, arguments...)
; registers in use:
; edi = pointer to out buffer
; esi = pointer to format buffer
; edx = flags register
; ebx = used to store width
; ecx = used for arguments pointer in esp

hw_sprintf:
    ; save callee-save registers
    push ebp
    push esi
    push edi
    push ebx

    ; edi - pointer to out buffer
    ; esi - pointer to format buffer
    mov edi, [esp + 20]
    mov esi, [esp + 24]
    lea ebp, [esp + 28]
    ; edx - register flags
    ; need to be se zero
    xor edx, edx

    ; main circle
    .next_character:
        mov cl, byte [esi] ; read next character
        inc esi

    .percent_sign:
        cmp cl, '%'
        je .parse_flags
        jne .simple_output

    .parse_flags:
        ; set percent flag
        or edx, percent_flag
        mov cl, byte [esi] ; read next character of flags
        inc esi
        ; check for plus sign
        ; and set plus_flag if necessary
        cmp cl, '+'
        je .set_plus
        ; check for space sign
        ; and set space_flag if necessary
        cmp cl, ' '
        je .set_space
        ; check for dash sign
        ; and set dash_flag if necessary
        cmp cl, '-'
        je .set_dash
        ; check for zero sign
        ; and set zero_flag if necessary
        cmp cl, '0'
        je .set_zero

        ; clear ebx for width parameter
        xor ebx, ebx
        ; width read circle
    .width_read:
        cmp cl, '0' ; check if cl >= '0'
        jge .is_lower ; if true check another bound
        jl .type_check
    .is_lower:
        cmp cl, '9' ; check if cl <= '9'
        jle .read_digit ; if true read digit
        jg .type_check
    .read_digit:
        or edx, width_flag ; set width flag
        imul ebx, 10 ; free space for new digit
        xor eax, eax ; clear register for current digit
        sub cl, '0'
        add al, cl
        add ebx, eax
        mov cl, byte [esi] ; read next character
        inc esi
        jmp .width_read

    ; check for type input
    .type_check:
        ; integer signed values
        cmp cl, 'i'
        je .print_int

        cmp cl, 'd'
        je .print_int
        jne .simple_output

    .print_int:
        call itoa
        ; clean flags and move pointer to next
        ; argument
        xor edx, edx
        add ebp, 4
        jmp .finally


    .simple_output:
        ; check for percent flag
        test edx, percent_flag
        ; if true print everything
        ; until percent sign
        jnz .print_until_percent
        ; if false put signel character in buffer
        jz .just_character

    .just_character:
        mov byte [edi], cl
        inc edi
        jmp .finally

    .print_until_percent
        ; clean percent_flag
        xor edx, percent_flag
        ; save pointer to current position
        ; in format string and width data
        push esi
        push ebx
        ; save esp to reverse
        mov ebx, esp
        dec esp
        jmp .push_until_percent
        ; push data in stack
    .push_until_percent:
        dec esi
        mov al, byte [esi]
        mov byte[esp], al
        dec esp
        cmp al, '%'
        jne .push_until_percent
        inc esp
        ; reverse data and put to
        ; out buffer
    .reverse_print_percent
        mov al, byte[esp]
        mov byte [edi], al
        inc edi
        inc esp
        cmp ebx, esp
        jne .reverse_print_percent
        ; release pushed registers
        pop ebx
        pop esi

    .finally:
        cmp cl, 0
        jne .next_character

        ; pop callee-save registers
        pop ebx
        pop edi
        pop esi
        pop ebp
        ret

    ; set plus flag to edx
    .set_plus:
        or edx, plus_flag
        jmp .parse_flags

    ; set space flag to edx
    .set_space:
        or edx, space_flag
        jmp .parse_flags

    ; set dash flag to edx
    .set_dash:
        or edx, dash_flag
        ; reset zero_flag if necessary
        test edx, zero_flag
        jnz .reset_zero
        jmp .parse_flags

    ; set zero flag to edx
    .reset_zero:
        xor edx, zero_flag
        jmp .parse_flags

    ; check for dash flag
    ; that can block zero flag
    .check_zero:
        test edx, dash_flag
        jz .set_zero
        jnz .parse_flags

    ; set zero flag to edx
    .set_zero:
        or edx, zero_flag
        jmp .parse_flags

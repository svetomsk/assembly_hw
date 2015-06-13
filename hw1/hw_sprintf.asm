global hw_sprintf
global itoa

section .text

plus_flag    equ   1 << 0 ; always print sign before number 1
space_flag   equ   1 << 1 ; always print space before number 2
align_flag   equ   1 << 2 ; align left 4 
zero_flag    equ   1 << 3 ; fill 0 up to min width 8
width_flag   equ   1 << 4 ; 16
percent_flag equ   1 << 5 ; if percent sign is present 32
negative_flag equ  1 << 6 ; if number if negative 64

; void sitoa(char * buf, int value, int flags, ...)
; eid = pointer to out buffer
; eax = value of be stored in buffer
; ebp = flags value
itoa:
    ; save registers
    push ebp
    push esi
    push edi
    push ebx

    mov edi, [esp + 20] ; edi = buf
    mov eax, [esp + 24] ; eax = value
    mov ebp, [esp + 28] ; ebp = flags

    test eax, 0x80000000 ; check for negative value
    je .main
    neg eax
    or ebp, negative_flag
    or ebp, plus_flag
    xor ebp, space_flag

    .main:
        mov ebx, 10 ; ebx = divisor
        mov ecx, esp ; save old esp value

        .div_circle: ; div until eax != 0
            xor edx, edx ; edx = 0
            div ebx; eax / ebx
            add edx, '0'; edx = '0' + last digit of eax
            dec esp
            mov byte [esp], dl
            cmp eax, 0
            jne .div_circle

        
        .test_width: ; if width is set
            xor ebx, ebx ; clear register for width
            test ebp, width_flag
            jz .sub_length
            mov ebx, [ecx + 32] ;ebx = width

        .sub_length:
            sub ecx, esp ; ecx = length of number

        .test_zero:
            test ebp, zero_flag ; if (ebp contains zero_flag)
            jz .test_sign ; else

            test ebp, plus_flag ; if(ebp contains plus_flag)
            jz .without_sign ; else
            jnz .with_sign

        .without_sign:
            cmp ecx, ebx
            jge .test_sign
            jl .with_space

        .with_sign:
            dec ebx
            cmp ecx, ebx
            jge .test_sign
            jl .push_zeros

        .with_space:
            test ebp, space_flag
            jz .push_zeros
            dec ebx

        .push_zeros:
            dec esp
            mov byte [esp], '0'
            inc ecx
            cmp ecx, ebx
            jl .push_zeros
            

        .test_sign:
            test ebp, plus_flag ; if(ebp contains plus_flag)
            jz .test_space ; else 

        .test_neg:
            test ebp, negative_flag ; if(ebp contains negative_flag)
            jz .push_plus ; else
            dec esp ; push '-' sign 
            mov byte [esp], '-'
            inc ecx
            jmp .test_align

        .push_plus: ; push '+' sign
            dec esp
            mov byte [esp], '+'
            inc ecx
            jmp .test_align

        .test_space: 
            test ebp, space_flag ; if(ebp contains space_flag)
            jz .test_align ; else
            dec esp ; push ' ' sign
            mov byte [esp], ' '
            inc ecx

        .test_align: 
            test ebp, align_flag
            jnz .reverse_circle

        cmp ecx, ebx ; if we got smth to push
        jge .reverse_circle

        .push_spaces_before:
            dec esp
            mov byte [esp], ' '
            inc ecx
            cmp ecx, ebx
            jne .push_spaces_before

        .reverse_circle: ; push to buffer until esp != old esp
            xor eax, eax; eax = 0
            mov al, byte [esp]; eax = current digit of value     
            inc esp
            mov byte [edi], al ; edi[i] = current digit of value
            inc edi
            dec ecx
            dec ebx
            cmp ecx, 0
            jne .reverse_circle

        test ebp, align_flag
        jz .finally
        cmp ebx, 0
        jle .finally

        .push_spaces_after:
            mov byte [edi], ' '
            inc edi
            dec ebx
            cmp ebx, 0
            jne .push_spaces_after

    .finally:    
        mov byte [edi], 0
        inc edi
        ; return registers back
        pop ebx
        pop edi
        pop esi
        pop ebp

        ret

; void hw_sprintf(char* out, char* format, arguments...)
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
    ; need to be zero
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
        ; check for align sign
        ; and set align_flag if necessary
        cmp cl, '-'
        je .set_align
        ; check for zero sign
        ; and set zero_flag if necessary
        cmp cl, '0'
        je .set_zero

        ; clear ebx for width parameter
        xor ebx, ebx
        ; width read circle
        .width_read:
            cmp cl, '0' ; check if cl >= '0'
            jge .is_lower ; if true check lower bound
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
        push edi
        push ebp
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
    .set_align:
        or edx, align_flag
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
        test edx, align_flag
        jz .set_zero
        jnz .parse_flags

    ; set zero flag to edx
    .set_zero:
        or edx, zero_flag
        jmp .parse_flags

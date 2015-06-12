global hw_sprintf
global itoa

section .text

plus_flag    equ   1 << 0 ; always print sign before number
space_flag   equ   1 << 1 ; always print space before number
align_flag   equ   1 << 2 ; align left
zero_flag    equ   1 << 3 ; fill 0 up to min width
width_flag   equ   1 << 4 ; 
percent_flag equ   1 << 5 ; if percent sign is present
negative_flag equ  1 << 6 ; if number if negative

; void sitoa(char * buf, int value, int flags)
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

    .reverse_circle: ; push to buffer until esp != old esp
        xor eax, eax; eax = 0
        mov al, byte [esp]; eax = current digit of value     
        inc esp
        mov byte [edi], al ; edi[i] = current digit of value
        inc edi
        cmp ecx, esp
        jne .reverse_circle

    ; return registers back
    pop ebx
    pop edi
    pop esi
    pop ebp

    ret

; ebp - pointer to argument int
; edi - pointer to out buffer
; use:
; eax for integer store
; edx for division
; ebx for division
; ecx for esp save state

; itoa:
;     ; save registers used in fucntion
;     push eax
;     push ebx
;     ; move argument value in eax
;     mov eax, [ebp]
;     ; check for signed negative value
;     test eax, 0x80000000
;     jne .signed_neg
;     jmp .main_process
;     .signed_neg:
;         neg eax
;         or edx, negative_flag

;     ; save edx
;     push edx
;     .main_process:
;         ; base for division
;         mov ebx, 10
;         ; save old esp value for reverse
;         mov ecx, esp
;         dec esp

;     .div_circle:
;         ; clean edx for division
;         xor edx, edx
;         div ebx
;         ; shift for character value
;         ; and put
;         add edx, '0'
;         ; put character to stask
;         ; and move pointer of esp
;         mov byte [esp], dl
;         dec esp
;         cmp eax, 0
;         jne .div_circle

;     ; ecx = old esp value
;     ; move to ecx amount of signs in stack
;     sub ecx, esp
;     ; pop edx to get flags values
;     pop edx
;     ; check for plus_flag
;     ; and push sign to stack if necessary
;     test edx, plus_flag
;     jz .after
;     ; check for negative sign
;     ; and put appropriate sign
;     test edx, negative_flag
;     jz .put_plus
;     mov byte[esp], '-'
;     jmp .after

;     .put_plus:
;         mov byte [esp], '+'
;         dec esp
;         inc ecx

;     .after:        
;         inc esp

;     .reverse_circle:
;         ; moves character from stask to out buffer
;         mov dl, byte [esp]
;         mov byte [edi], dl
;         inc edi
;         inc esp
;         dec ecx
;         cmp ecx, 0
;         jne .reverse_circle

;     pop ebx
;     pop eax
;     ret

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

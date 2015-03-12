global hw_sprintf

section .text

hw_sprintf:
    push ebp
    push esi
    push edi
    push ebx


    pop ebx
    pop edi
    pop esi
    pop ebp
    ret

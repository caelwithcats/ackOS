global _start

section .text
bits 32
_start:
    cli
    cld

    ; backup multiboot information that we can access in long mode
    mov dword[multiboot2_header], ebx
    mov dword[multiboot2_magic], eax

    ; initialise stack
    mov esp, _kernel_stack_top

    ; do all the checks
    call cpuid_check_long_mode

    call set_up_page_tables
    call enable_paging

    ; load gdt
    lgdt [_gdt_descriptor]
    jmp _gdt.code:long_mode_start

; thanks to https://os.phil-opp.com/entering-longmode/
cpuid_check_long_mode:
    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000001
    jb .no_long_mode

    mov eax, 0x80000001
    cpuid
    test edx, 1 << 29
    jz .no_long_mode
    ret
.no_long_mode:
    mov al, "2"
    jmp loader_print_error

global enable_a20
enable_a20:
    in al, 0x92
    or al, 2
    out 0x92, al
    ret

global set_up_page_tables
set_up_page_tables:
    ; map first P4 entry to P3 table
    mov eax, p3_table
    or eax, 0b11 ; present + writable
    mov [p4_table], eax

    ; map first P3 entry to P2 table
    mov eax, p2_table
    or eax, 0b11 ; present + writable
    mov [p3_table], eax

    mov ecx, 0

.p2_table_map:
    ; map ecx-th P2 entry to a huge page that starts at address 2MiB*ecx
    mov eax, 0x200000  ; 2MiB
    mul ecx            ; start address of ecx-th page
    or eax, 0b10000011 ; present + writable + huge
    mov [p2_table + ecx * 8], eax ; map ecx-th entry

    inc ecx            ; increase counter
    cmp ecx, 512       ; if counter == 512, the whole P2 table is mapped
    jne .p2_table_map  ; else map the next entry

    ret

global enable_paging
enable_paging:
    mov eax, p4_table
    mov cr3, eax

    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr

    ; enable paging in the cr0 register
    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax

    ret

print:
	mov ecx, 0xb8000
.loop:
    mov ah, byte[ebx]
    cmp ah, byte 0
    je .exit
    mov byte[ecx], ah
    add ecx, 2
    add ebx, 1

    jmp .loop
.exit:
    ret

; Errors
loader_print_error:
    mov byte [0xb8000], "e"
    mov byte [0xb8002], "r"
    mov byte [0xb8004], "r"
    mov byte [0xb8006], "o"
    mov byte [0xb8008], "r"
    mov byte [0xb800a], " "

    mov byte [0xb800c], al
    mov byte [0xb800e], " " ; Remove any extra text such as QEMU status

    hlt
    ret

loader_print_unknown_err:
    mov al, "9"
    call loader_print_error

section .bss
align 4096
; Paging tables
p4_table:
    resb 4096

p3_table:
    resb 4096

p2_table:
    resb 4096

section .data
_gdt:
    .zero: equ $ - _gdt
        dq 0 ; zero entry

    .code: equ $ - _gdt
        dw 0x0000       ; limit
        dw 0x0000       ; base (low 16 bits)
        db 0x00         ; base (mid 8 bits)
        db 10011010b    ; access
        db 00100000b    ; granularity
        db 0x00         ; base (high 8 bits)

    .data: equ $ - _gdt
        dw 0            ; limit
        dw 0            ; base (low 16 bits)
        db 0            ; base (mid 8 bits)
        db 10010010b    ; access
        db 00000000b    ; granularity
        db 0            ; base (high 8 bits)

    .task: equ $ - _gdt
        dq 0
        dq 0

        dw 0

_gdt_descriptor:
    dw $ - _gdt - 1
    dq _gdt

extern _kernel_stack_top
extern _kernel_stack_bottom

multiboot2_header: dq 0
multiboot2_magic: dq 0

section .text
; We are now in 64-bit long mode!
bits 64
long_mode_start:
    mov ax, 0
    mov ss, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    extern x86_64_init

    mov edi, dword[multiboot2_header]
    mov esi, dword[multiboot2_magic]

    call x86_64_init

    hlt

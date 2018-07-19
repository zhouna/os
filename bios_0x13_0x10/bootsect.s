BOOTSEG equ 0x7c0

section .text vstart=0

jmp BOOTSEG:start

start:
	mov ax, cs
	mov ds, ax
	mov ss, ax

        mov ax, 0x0203
        mov cx, 0x0002
        mov dx, 0x0000
        mov bx, 0x1000
        mov es, bx
        xor bx, bx
        int 0x13

        jnc ok_load

        mov bp, failMsg
	call dispstr
        jmp $

ok_load:
        mov bp, okMsg
        call dispstr
        jmp $
        
        
dispstr:
	mov ax, 0
	mov es, ax
        mov ax, 0x1301
        mov bx, 0x004f
	mov cx, 3
        mov dx, 0x0101
        int 0x10
        ret


okMsg: db "ok", 0
failMsg: db "fa", 0

times 510-($-$$) db 0
dw 0xaa55

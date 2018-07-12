org 0x7c00

mov ax, cs
mov ds, ax
mov es, ax

call dispstr
jmp $

dispstr:
	mov ax, 0x1301
	mov bx, 0x000c
	mov cx, 10
	mov dx, 0x1010
	mov bp, BootMessage
	int 0x10
	ret

BootMessage: db "hello os!", 0

times 510-($-$$) db 0
dw 0xaa55

;机器已启动就把这段代码加载到0x7c00处
;显示一段字符串，然后进入死循环
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
	mov dx, 0x00
	mov bp, BootMessage
	int 0x10
	ret

BootMessage: db 'hello os!', 0

times 510-($-$$) db 0
dw 0xaa55
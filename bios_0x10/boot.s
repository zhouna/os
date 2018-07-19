;bios中断
;int 0x10 显示服务
;ah=0x13 在Teletype模式下显示字符串

BOOTSEG equ 0x7c0

section .text vstart=0

jmp BOOTSEG:start

start:
	mov ax, cs
	mov ss, ax
	mov ds, ax
	mov es, ax    

	mov bp, msg    ;入口参数：
        mov ax, 0x1301 ; ah=0x13 al=显示输出方式 01表示字符串只含有显示字符，其属性在BL中。显示后光标位置改变
        mov bx, 0x0002 ; bh页码 bl属性（若al=0或1）
	mov cx, 3      ; cx显示的字符串长度
        mov dx, 0x0101 ; dh行 dl列
        int 0x10       ; es:bp显示字符串的地址
	jmp $
	
msg: db "ok", 0

times 510-($-$$) db 0
dw 0xaa55

BOOTSEG equ 0x07c0
SYSSEG equ 0x1000
SYSLEN equ 17

section .text vstart=0

jmp BOOTSEG:start

start:
	mov ax, cs
	mov ss, ax
	mov ds, ax

	;读磁盘
	mov ax, 0x0200+SYSLEN
        mov cx, 0x0002
        mov dx, 0x0000
        mov bx, SYSSEG
        mov es, bx
        xor bx, bx
        int 0x13

        jnc ok_load

ok_load:
	;移动到内存0x0处（原地址ds:si，目的地址es:di）
	cli
	mov ax, SYSSEG
	mov ds, ax
	xor ax, ax
	mov es, ax
	mov cx, SYSLEN*512
	sub si, si
	sub di, di
	rep movsw

	;加载idt和gdt基地址寄存器idtr和ldtr
	mov ax, BOOTSEG
	mov ds, ax
	lidt [idt_48]
	lgdt [gdt_48]
	
	;设置cr0寄存器到pe位，进入保护模式
	mov ax, 0x0001
	lmsw ax
	jmp 8:0

gdt:
	dw 0,0,0,0
	
	dw 0x07ff ;代码段
	dw 0x0000
	dw 0x9a00
	dw 0x00c0

	dw 0x07ff ;数据段
	dw 0x0000
	dw 0x9200
	dw 0x00c0

idt_48:
	dw 0
	dw 0,0

gdt_48:
	dw 0x7ff
	dw 0x7c00+gdt,0

times 510-($-$$) db 0
dw 0xaa55

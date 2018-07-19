[BITS 32]

SCRN_SEL equ 0x18

section .text vstart=0

;现在是保护模式
;
;重新定义gdt
;除了代码段、数据段再定义一个显示内存段（0xb8000开始的显存）
;
;在内核代码段中执行不断打印字母'A'的程序

start_up:
	mov eax, 0x10
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	lss esp, [init_stack]	

	lgdt [lgdt_opcode]	

f:	mov al, 'A'
	call print
	jmp f

print:
	;打印字母al中的字母
	mov ebx, SCRN_SEL
	mov gs, bx
	mov ebx, [scr_loc]
	shl ebx, 1
	mov byte [gs:ebx], al
	mov byte [gs:ebx+1], 07
	shr ebx, 1
	inc ebx
	cmp ebx, 2000
	jb l
	mov ebx, 0
l:	mov [scr_loc], ebx
	ret

scr_loc dd 0 ; 如果dd大于2000就复位为0，因为屏幕是25*80=2000，一屏最多显示2000个字符

lgdt_opcode:
	dw (end_gdt-gdt)-1
	dw gdt, 0

;gdt:	dq 0x0000_0000_0000_0000 ;gdt表。第一项不用
;	dq 0x00c0_9a00_0000_07ff ;内核代码段。其选择符是0x08
;	dq 0x00c0_9200_0000_07ff ;内核数据段。其选择符是0x10
;	dq 0x00c0_920b_8000_0002 ;显示内存段。其选择符是0x18

gdt:	dw 0,0,0,0
	;dq 0x0000000000000000 why not work?	

	dw 0x07ff ;代码段
	dw 0x0000
	dw 0x9a00
	dw 0x00c0

	dw 0x07ff ;数据段
	dw 0x0000
	dw 0x9200
	dw 0x00c0
	
	dd 0x80000002
	dd 0x00c0920b	

end_gdt:
	times 128 dd 0        ;内核堆栈段
init_stack:
	dd init_stack         ; esp
	dw 0x10		      ; ss

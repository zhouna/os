[BITS 32]

SCRN_SEL equ 0x1f
LDT0_SEL equ 0x28
TSS0_SEL equ 0x20

section .text vstart=0

;现在是保护模式
;
;重新定义gdt
;除了代码段、数据段、显示内存段（0xb8000开始的显存），还定义了一个任务0（TSS0，LDT0）
;
;任务0中执行不断打印字母'A'的程序（运行在用户态）
;
;如何从内核代码跳入用户代码：
;   设置tr，即tss0的段选择符
;   设置ldt，即ldt0的段选择符
;   将原ss，原esp，EFLAGS，cs，eip依次入栈，
;     然后iret，执行中断返回指令，从而切换到特权级3的任务0中执行

start_up:
	mov eax, 0x10
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	lss esp, [init_stack]	

	lgdt [lgdt_opcode]	

	mov eax, 0x10
        mov ds, ax
        mov es, ax
        mov fs, ax
        mov gs, ax
        lss esp, [init_stack]

	;移动到任务0中，在堆栈中人工建立中断返回时到场景
	pushf
	and dword [esp], 0xffffbfff 
	popf
	mov eax, TSS0_SEL
	ltr ax
	mov eax, LDT0_SEL
	lldt ax
	sti ;开启中断
	push dword 0x17
	push init_stack
	pushf
	push dword 0x0f
	push fn
	iret


scr_loc dd 0 ; 如果dd大于2000就复位为0，因为屏幕是25*80=2000，一屏最多显示2000个字符

lgdt_opcode:
	dw (end_gdt-gdt)-1
	dw gdt, 0

;gdt:	dq 0x0000_0000_0000_0000 ;gdt表。第一项不用
;	dq 0x00c0_9a00_0000_07ff ;内核代码段。其选择符是0x08
;	dq 0x00c0_9200_0000_07ff ;内核数据段。其选择符是0x10
;	dq 0x00c0_920b_8000_0002 ;显示内存段。其选择符是0x18

gdt:	dw 0,0,0,0            ;gdt表。第一项不用 
	;dq 0x0000000000000000;why not work?	

	dw 0x07ff 	      ;内核代码段。其选择符是0x08
	dw 0x0000
	dw 0x9a00
	dw 0x00c0

	dw 0x07ff 	      ;内核数据段。其选择符是0x10
	dw 0x0000
	dw 0x9200
	dw 0x00c0
	
	dd 0x80000002         ;显示内存段。其选择符是0x18
	dd 0x00c0920b	

	dw 0x68, tss0, 0xe900, 0x0 ;tss0段的描述符。其选择符是0x20
	dw 0x40, ldt0, 0xe200, 0x0 ;ldt0段的描述符。其选择符是0x28

end_gdt:
	times 128 dd 0        ;内核堆栈段
init_stack:
	dd init_stack         ; esp
	dw 0x10		      ; ss

ldt0:	dd 0x00000000         ;任务0的局部描述符表
	dd 0x00000000         ;第一个描述符，不用

	dd 0x000003ff         ;局部代码段描述符。其选择符是0x0f
	dd 0x00c0fa00	      

	dd 0x000003ff         ;局部数据段描述符。其选择符是0x17
        dd 0x00c0f200         

	dd 0x80000002         ;显示内存段。其选择符是0x1f
        dd 0x00c0f20b

tss0:	dd 0
	dd krn_stk0,0x10
	dd 0,0,0,0,0
	dd 0,0,0,0,0
	dd 0,0,0,0,0
	dd 0,0,0,0,0,0
	dd LDT0_SEL, 0x8000000 

	times 128 dd 0        ;任务0的内核栈空间
krn_stk0:

;任务0的代码
fn:	mov eax, 0x17
	mov ds, eax
	mov al, 'A'
	call print
	jmp fn

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

[BITS 32]
LATCH equ 1193180
SCRN_SEL equ 0x18
LDT0_SEL equ 0x28
TSS0_SEL equ 0x20
LDT1_SEL equ 0x38
TSS1_SEL equ 0x30

section .text vstart=0

;现在是保护模式
;
;定义gdt
;代码段、数据段、显示内存段（0xb8000开始的显存）、任务0（TSS0，LDT0）、任务1（TSS1, LDT1）
;
;定义idt，256项
;0x08时钟中断
;0x80系统调用
;其余各项用默认的程序ignore_int
;
;任务0执行不断打印字母'A'的程序（运行在用户态）
;任务1执行不断打印字母'B'的程序（运行在用户态）
;
;打印程序是内核代码，用户任务通过系统调用执行内核代码
;两个任务在时钟中断下不断交替运行
;
;如何从内核代码跳入用户代码：
;   设置tr，即tss0的段选择符
;   设置ldt，即ldt0的段选择符
;   将原ss，原esp，EFLAGS，cs，eip依次入栈，
;     然后iret，执行中断返回指令，从而切换到特权级3的任务0中执行
;
;时钟中断是通过8253定时芯片发出的，要对这个芯片进行设置

start_up:
	mov eax, task0
	mov eax, task1
	mov eax, print
	mov eax, ignore_int
	mov eax, ignore_int1
	mov eax, system_interrupt
	mov eax, timer_interrupt
	mov eax, 0x10
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	lss esp, [init_stack]	

	;设置idt
	call setup_idt

	;设置gdt
	lgdt [lgdt_opcode]	

	;在改变了gdt之后，从新加载所有段寄存器
	mov eax, 0x10
        mov ds, ax
        mov es, ax
        mov fs, ax
        mov gs, ax
        lss esp, [init_stack]

	;设置8253定时芯片
	mov al, 0x36
	out 0x43, al
	mov eax, LATCH
	out 0x40, al
	mov al, ah
	out 0x40, al

	;设置IDT表的第0x08项，timer_interrupt
	mov edx, timer_interrupt
        ;mov edx, ignore_int1
	mov eax, 0x00080000
	mov ax, dx
	mov dx, 0x8e00
	mov [idt+0x08*8], eax
	mov [idt+0x08*8+4], edx
	;设置IDT表的第0x80项，system_interrupt
	mov edx, system_interrupt
        mov eax, 0x00080000
        mov ax, dx
        mov dx, 0xef00   ;;;;;;;;;;;;;;???????陷阱门类型15，特权级3的程序可执行
        mov [idt+0x80*8], eax
        mov [idt+0x80*8+4], edx

	;移动到任务0中，在堆栈中人工建立中断返回时到场景
	pushf
	and dword [esp], 0xffffbfff 
	popf
	mov eax, TSS0_SEL
	ltr ax
	mov eax, LDT0_SEL
	lldt ax
	mov dword [current], 0
	sti ;开启中断
	push dword 0x17
	push init_stack
	pushf
	push dword 0x0f
	push task0
	iret

setup_idt:
	;设置idt，先都设为默认的处理程序ignore_int
	mov edx, ignore_int
	mov eax, 0x00080000
	mov ax, dx
	mov dx, 0x8e00
	mov edi, idt
	mov ecx, 256
rp_idt:	mov [edi], eax
	mov [edi+4], edx
	add edi, 8
	dec ecx
	jne rp_idt
	lidt [lidt_opcode]
	ret	

print:
	;打印字母al中的字母
	push gs		;保存要用到的寄存器，EAX由调用者负责保存。
	push ebx
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
	pop ebx
	pop gs
	ret

ignore_int:
	;默认中断处理程序。
	;在屏幕上显示一个字符‘C’
	push ds
	push eax
        mov eax, 0x10
	mov ds, ax
	mov al, 'C'
        call print
        pop eax
	pop ds
	iret

ignore_int1:
        ;默认中断处理程序。
        ;在屏幕上显示一个字符‘C’
        push ds
        push eax
        mov eax, 0x10
        mov ds, ax
       	mov al, 0x20
	out 0x20, al
	mov al, 'S'
        call print
        pop eax
        pop ds
        iret

timer_interrupt:
	;定时中断处理程序，执行任务切换。
	push ds
	push eax
	mov eax, 0x10	;让DS指向内核数据段
        mov ds, ax
	mov al, 0x20	;允许其他中断，即向8259A发送EOI命令
	out 0x20, al
	
	mov eax, 1
	cmp dword [current], eax
	je t_1
	;当前任务是0，把1存人current，并跳转到任务1去执行
	mov dword [current], 1
	jmp TSS1_SEL:0
	jmp t_2

	;当前任务是1，把0存人current，并跳转到任务0去执行
t_1:	mov dword [current], 0
	jmp TSS0_SEL:0

t_2:	pop eax
	pop ds
	
	iret

system_interrupt:
	;系统调用中断int 0x80处理程序。
	;只有一个显示字符功能。
	push ds
	push edx
        mov edx, 0x10
        mov ds, dx
       	call print
	pop edx
        pop ds
        iret

current dd 0 ;当前任务号（0或1）
scr_loc dd 0 ; 如果dd大于2000就复位为0，因为屏幕是25*80=2000，一屏最多显示2000个字符

lidt_opcode:
	dw 256*8-1	      ;加载IDTR寄存器的6字节操作数：32位IDT基地址，16位以字节位单位的限长。
	dw idt, 0
lgdt_opcode:		      ;加载GDTR寄存器的操作数。
	dw (end_gdt-gdt)-1
	dw gdt, 0

idt:	times 256 dd 0, 0     ;IDT空间。共256个门描述符，每个8字节。

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
	
	dw 0x68, tss1, 0xe900, 0x0 ;tss1段的描述符。其选择符是0x30
        dw 0x40, ldt1, 0xe200, 0x0 ;ldt1段的描述符。其选择符是0x38

end_gdt:
	times 128 dd 0        ;内核堆栈段
init_stack:
	dd init_stack         ; esp
	dw 0x10		      ; ss

;下面是任务0的LDT表段内容和TSS段内容

ldt0:	dd 0x00000000         ;任务0的局部描述符表
	dd 0x00000000         ;第一个描述符，不用

	dd 0x000003ff         ;局部代码段描述符。其选择符是0x0f
	dd 0x00c0fa00	      

	dd 0x000003ff         ;局部数据段描述符。其选择符是0x17
        dd 0x00c0f200         

tss0:	dd 0
	dd krn_stk0,0x10
	dd 0,0,0,0,0
	dd 0,0,0,0,0
	dd 0,0,0,0,0
	dd 0,0,0,0,0,0
	dd LDT0_SEL, 0x8000000 

	times 128 dd 0        ;任务0的内核栈空间
krn_stk0:

;下面是任务1的LDT表段内容和TSS段内容

ldt1:   dd 0x00000000         ;任务0的局部描述符表
        dd 0x00000000         ;第一个描述符，不用

        dd 0x000003ff         ;局部代码段描述符。其选择符是0x0f
        dd 0x00c0fa00

        dd 0x000003ff         ;局部数据段描述符。其选择符是0x17
        dd 0x00c0f200

tss1:   dd 0			;back link
        dd krn_stk1,0x10	;esp0, ss0
        dd 0,0,0,0,0		;esp1, ss1, esp2, ss2, cr3
        dd task1,0x200		;eip, eflags
        dd 0,0,0,0		;eax, ecx, edx, ebx
	dd usr_stk1,0,0,0			;esp, ebp, esi, edi
        dd 0x17,0x0f,0x17,0x17,0x17,0x17	;es, cs, ss, ds, fs, gs
        dd LDT1_SEL, 0x8000000	;ldt选择符, i/0位图基地址

        times 128 dd 0        ;任务0的内核栈空间
krn_stk1:

;任务0
task0:	mov eax, 0x17
	mov ds, eax
	mov al, 'A'
	int 0x80
	mov ecx, 0xfff
t0_1:	loop t0_1
	jmp task0

;任务1
task1:	mov al, 'B'
	int 0x80
	mov ecx, 0xfff
t1_1:	loop t1_1
	jmp task1
	
	times 128 dd 0         ;任务1的用户栈空间
usr_stk1:


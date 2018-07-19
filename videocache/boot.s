;在屏幕显示字符
;不过不用bios中断，而是直接在显存里写
;显存地址0xb8000-0xbffff共32KB的空间，为80*25彩色字符模式的显示缓冲区，向这个地址空间写入数据，写入的内容立即出现在显示器上
;25行*80个字符，字符一个字节，属性一个字节
;一屏80*25*2=4000Bytes
;
;属性
;7   6 5 4  3  2 1 0
;BL  R G B  I  R G B
;   ------     ----- 
;闪烁 背景 高亮 前景

BOOTSEG equ 0x7c0
VIDEO equ 0xb800

section .text vstart=0

jmp BOOTSEG:start

start:
	mov ax, VIDEO
	mov ds, ax

	mov byte [0], 'a'
	mov byte [1], 0x42
	
	jmp $
	
times 510-($-$$) db 0
dw 0xaa55

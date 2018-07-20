; 编译链接方法
; (ld的'-s'选项意为"stripall")
;
; $nasm -f elf foo.asm -o foo.o
; $gcc -c bar.c -o bar.o
; $ld -s hello.o bar.o -o footbar
; $./foobar
; the 2nd one
; $

extern choose ; int choose(int a, int b);

[section .data]

num1st dd 3
num2nd dd 4

[section .text]

global _start
global myprint

_start:
push dword [num2nd]
push dword [num1st]
call choose
add esp, 8

mov ebx, 0
mov eax, 1 ; sys_exit
int 0x80 ; 系统调用

; void myprint(char* msg, int len)
myprint:
mov edx, [esp+8] ; len
mov ecx, [esp+4]; msg
mov ebx, 1
mov eax, 4 ; sys_write
int 0x80
ret



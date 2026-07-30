[BITS 16]
[org 0x7c00]
; we have 510 bytes to use here (perfect for snake!)

%define GAME_WIDTH 20 ; max 255
%define GAME_HEIGHT 20 ; max 255
%define GAME_SCALE 1
%define GRID_SPACING 1
; AFA0

%define SNAKE_ARRAY_START 0x1000
%define SNAKE_MAX_LEN GAME_WIDTH*GAME_HEIGHT


mov ax,	0xA000 ; offset of base pointer for vga framebuffer
mov ds,	ax

mov ax,	0x0000
mov ss,	ax
mov sp,	0x7c00 ; set up stack pointer and stack offset to be below code (if it overflows it will do bad weird stuff though)

main:

	call init

	mov al,2
	call clearscr

	;mov ax,320/2 - 100/2
	;mov bx,200/2 - 75/2
	;mov cx,100
	;mov dx,75
	;push 4
	;call rect
	

	


	
	hlt ; wait for refresh (or something)
	jmp main



%include "src/graphics.asm"

times 510-($-$$) db 0
db 0x55, 0xaa ; in order to make disk bootable

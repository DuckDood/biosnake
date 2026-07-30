[BITS 16]
[org 0x7c00]
; we have 510 bytes to use here (perfect for snake!)

%define GAME_WIDTH 20 ; max 255
%define GAME_HEIGHT 20 ; max 255
%define GAME_SCALE 5
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

	mov al,10
	call clearscr

	;mov ax,320/2 - 100/2
	;mov bx,200/2 - 75/2
	;mov cx,100
	;mov dx,75
	;push 4
	;call rect

	mov cx,GAME_SCALE
	mov dx,GAME_SCALE

	mov ax, 0
	mov bx, 0
	


.griddrawloopouter:
	cmp bx, GAME_HEIGHT
	je .griddrawouterend
	.griddrawloopinner:
	cmp ax, GAME_WIDTH
	je .griddrawloopinnerend
	; funky loop stuff done, code here (ax is x, bx is y)

	mov dx,GAME_SCALE
	mov cx,GAME_SCALE


	push ax ; x pos
	push bx ; y pos
	
	; cx and dx should have game scale because the rect needs to be that size anyway

	mul cx ; multiplies ax by cx

	push ax ; multiplied x coord

	mov ax,bx
	mul cx
	push ax ; multiplied y coord

	pop bx
	pop ax

	mov dx,GAME_SCALE
	mov cx,GAME_SCALE

	add ax,GRID_SPACING
	add bx,GRID_SPACING

	sub cx,GRID_SPACING
	sub dx,GRID_SPACING

	
	; draw rect with color 15
	push ax
	push 15
	call rect
	pop ax
	pop ax

	pop bx
	pop ax
	
	
	; more funky loop stuff
	inc ax
	jmp .griddrawloopinner
	.griddrawloopinnerend:

	mov ax,0
	inc bx
	jmp .griddrawloopouter
	
.griddrawouterend:
	
	hlt ; wait for refresh (or something)
	jmp main



%include "src/graphics.asm"

times 510-($-$$) db 0
db 0x55, 0xaa ; in order to make disk bootable

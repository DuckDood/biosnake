[BITS 16]
[org 0x7c00]
; we have 510 bytes to use here (perfect for snake!)

%define GAME_WIDTH 20 ; max 255
%define GAME_HEIGHT 20 ; max 255
%define GAME_SCALE 8
%define GRID_SPACING 1
%define MOVEMENT_COUNT_THRESHOLD 10


%define MOVEMENT_COUNTER 0x0996 ; frame count until snake actually moves so it doesnt speed along at ~60 units/s
%define SNAKE_DIRECTION 0x0997 ; direction only takes up 2 bits worth but might as well make it 1 byte i don't think im that desperate for memory
%define SNAKE_LENGTH 0x0998 ; 2 bytes

%define SNAKE_TAIL_OFFSET 0x1000 ; two bytes (0x1000 and 0x1001)
%define SNAKE_HEAD_OFFSET 0x1002 ; two bytes (0x1002 and 0x1003)

%define SNAKE_ARRAY_START 0x1004 ; arranged in x,y,x,y order
%define SNAKE_MAX_LEN GAME_WIDTH*GAME_HEIGHT

; first things first load the extra sector

mov ax,0
mov es,ax
mov bx,0x7e00

mov ah,0x2
mov al,2 ; 2 sectors is probably fine

mov ch,0x0
mov cl,2 ; start at sector 2
mov dh,0 ; 

mov dl,0x80

int 0x13

mov ax,	0x0000
mov ds,	ax

mov ax,	0x0000
mov ss,	ax

mov sp,	0x7c00 ; set up stack pointer and stack offset to be below code (if it overflows it will do bad weird stuff though)

mov [MOVEMENT_COUNTER],0

mov [SNAKE_HEAD_OFFSET],0
mov [SNAKE_TAIL_OFFSET],0

mov [SNAKE_ARRAY_START],0
mov [SNAKE_ARRAY_START+1],0


mov [SNAKE_LENGTH],1
mov [SNAKE_DIRECTION],0
call init

main:
	
	
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


	mov ah,0x1
	int 0x16 ; if zero flag is 0 key is down

	;jnz .movecool; jump not zero (zf is 0)
	jz .moveend ; if zero flag is not zero (meaning zero flag is true, meaning jz) jump past the key handle stuff

	.movecool:
	mov ah,0x0
	int 0x16 ; if zero flag is 0 key is down
	;inc [SNAKE_DIRECTION]

	cmp al,'d'
	je .keyd

	cmp al,'w'
	je .keyw

	cmp al,'a'
	je .keya

	cmp al,'s'
	je .keys

	cmp al,'e'
	je .keye
	 
	 ; snake direction 0,1,2,3 corresponds to right,up,left,down

	jmp .moveend

		.keyd:
			mov [SNAKE_DIRECTION],0
			jmp .moveend

		.keyw:
			mov [SNAKE_DIRECTION],1
			jmp .moveend

		.keya:
			mov [SNAKE_DIRECTION],2
			jmp .moveend

		.keys:
			mov [SNAKE_DIRECTION],3
			jmp .moveend

		.keye:
			call growsnake
			jmp .moveend
	
	.moveend:

	inc [MOVEMENT_COUNTER]

	cmp [MOVEMENT_COUNTER],MOVEMENT_COUNT_THRESHOLD
	jb .endsnakemove

	; this happens when the movement counter hits

	mov [MOVEMENT_COUNTER],0 ; reset movement countdown


	;inc [SNAKE_HEAD_OFFSET]
	;mov bx,[SNAKE_HEAD_OFFSET]



	mov ax,[SNAKE_HEAD_OFFSET]
	mov bx,2
	mul bx
	mov bx,ax


	push [SNAKE_ARRAY_START + bx] ; current position
	
	inc [SNAKE_HEAD_OFFSET]

	; because i dont know how to do modulos in asm
	mov ax,[SNAKE_HEAD_OFFSET]
	cmp ax,[SNAKE_LENGTH]
	jne .dont_loop
	sub ax,[SNAKE_LENGTH]

	.dont_loop:
	mov [SNAKE_HEAD_OFFSET],ax

	;inc [SNAKE_LENGTH]

	mov ax,[SNAKE_HEAD_OFFSET]
	mov bx,2
	mul bx
	mov bx,ax

	pop [SNAKE_ARRAY_START + bx] ; current position


	

	cmp [SNAKE_DIRECTION],0
	je .movright
	cmp [SNAKE_DIRECTION],1
	je .movup
	cmp [SNAKE_DIRECTION],2
	je .movleft
	cmp [SNAKE_DIRECTION],3
	je .movdown

	jmp .endsnakemove

	
	.movright:
		inc [SNAKE_ARRAY_START + bx]
		jmp .endsnakemove
	.movup:
		dec [SNAKE_ARRAY_START+1 + bx]
		jmp .endsnakemove
	.movleft:
		dec [SNAKE_ARRAY_START + bx]
		jmp .endsnakemove
	.movdown:
		inc [SNAKE_ARRAY_START+1 + bx]
		jmp .endsnakemove

	.endsnakemove:

	push 0

	mov si,[SNAKE_LENGTH]

	.snakedrawloop:
	cmp si,0
	jz .snakedrawend
	dec si

	call loadgridcoords
	mov cx,GAME_SCALE
	mov dx,GAME_SCALE

	inc ax
	inc bx
	dec cx
	dec dx
	call rect

	jmp .snakedrawloop
	.snakedrawend:

	pop ax

	push [SNAKE_DIRECTION]
	mov ax,0
	mov bx,0
	mov cx,10
	mov dx,10
	;call rect
	pop ax

	


	call waitscreen ; will wait for screen to pause for a sec while the electron gun or whatever it is in an emulator resets
	call show ; super quick copy buffer in between reset


	jmp main

loadgridcoords: ; put which snake segment you want in si and puts x and y in ax and bx


	push si
	mov ax,si
	mov bx,2
	mul bx
	mov si,ax
	

	mov bl,GAME_SCALE

	xor ax,ax
	mov al,[SNAKE_ARRAY_START + si]
	mul bl
	push ax ; x on stack

	xor ax,ax
	mov al,[SNAKE_ARRAY_START+1 + si]
	mul bl
	push ax ; y on stack
	pop bx
	pop ax

	pop si

	ret


growsnake:
	inc [SNAKE_LENGTH]
	; now i need to move everything after the head over by one space (two bytes)

	;works but kinda weird
	;mov ax,[SNAKE_HEAD_OFFSET] 
	;inc ax
	;mov bx,2
	;mul bx
	;push ax


	;mov ax,[SNAKE_LENGTH] ; end of array index
	;mov bx,2
	;mul bx
	;mov bx,ax
	;pop ax
	;.growloop:
	;cmp ax,bx
	;je .growend

	;mov cx, [SNAKE_ARRAY_START-2 + bx]
	;mov [SNAKE_ARRAY_START + bx],cx
	;dec bx
	;dec bx


	;jmp .growloop
	;.growend:

	mov bx,[SNAKE_LENGTH]


	.growloop:
	mov ax,[SNAKE_HEAD_OFFSET]
	cmp ax,bx
	je .growend

	push bx
	mov ax,bx
	mov cx,2
	mul cx
	mov bx,ax ; multiplies bx by 2 because we're doing 16 bit instead of 8

	mov cx,[SNAKE_ARRAY_START-2 + bx]
	mov [SNAKE_ARRAY_START + bx],cx

	pop bx

	dec bx
	jmp .growloop

	.growend:

	ret
	




times 510-($-$$) db 0
db 0x55, 0xaa ; in order to make disk bootable

%include "src/graphics.asm"

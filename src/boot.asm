[BITS 16]
[org 0x7c00]

%define GAME_WIDTH 30 ; max 127
%define GAME_HEIGHT 20 ; max 127
%define GAME_SCALE 8
%define GRID_SPACING 0
%define MOVEMENT_COUNT_THRESHOLD 5


%define RANDSEED 0x0992

%define APPLE_POSITION 0x0994 ; two bytes for position

%define MOVEMENT_COUNTER 0x0996 ; frame count until snake actually moves so it doesnt speed along at ~60 units/s
%define SNAKE_DIRECTION 0x0997 ; direction only takes up 2 bits worth but might as well make it 1 byte i don't think im that desperate for memory
%define SNAKE_LENGTH 0x0998 ; 2 bytes

%define WANTED_DIRECTION 0x099A; where the user wants to go before we actually change the direction (i inserted this into here because i had some unused variables, but i might want to turn it into a queue with the extra byte)
%define SNAKE_HEAD_OFFSET 0x099C ; two bytes (0x099C and 0x099E)

%define SNAKE_ARRAY_START 0x1000 ; arranged in x,y,x,y order
%define SNAKE_MAX_LEN GAME_WIDTH*GAME_HEIGHT

; first things first load the extra sector

;mov ax,0
xor ax,ax
mov es,ax
mov bx,0x7e00

mov ah,0x2
mov al,4 ; 2 sectors is probably fine

;mov ch,0x0
xor ch,ch
mov cl,2 ; start at sector 2
mov dh,0 ; 

mov dl,0x80

int 0x13

mov ax,	0x0000
mov ds,	ax

mov ax,	0x0000
mov ss,	ax

mov sp,	0x7c00 ; set up stack pointer and stack offset to be below code (if it overflows it will do bad weird stuff though)

call initvars
call init

jmp main

; might want to move main back here if i can make it fit
times 510-($-$$) db 0
db 0x55, 0xaa ; in order to make disk bootable

main:
	
	
	mov al,10
	call clearscr

	;mov ax,320/2 - 100/2
	;mov bx,200/2 - 75/2
	;mov cx,100
	;mov dx,75
	;push 4
	;call rect

	;mov cx,GAME_SCALE
	;mov dx,GAME_SCALE

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

	;mov ax,0
	xor ax,ax
	inc bx
	jmp .griddrawloopouter
	
.griddrawouterend:


	mov ah,0x1
	int 0x16 ; if zero flag is 0 key is down

	;jnz .movecool; jump not zero (zf is 0)
	jz .moveend ; if zero flag is not zero (meaning zero flag is true, meaning jz) jump past the key handle stuff

	.movecool:
	;mov ah,0x0
	xor ah,ah
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

	cmp al,'p'
	je .keyp
	 
	 ; snake direction 0,1,2,3 corresponds to right,up,left,down

	jmp .moveend

		.keyd:
			mov [WANTED_DIRECTION],0
			jmp .moveend

		.keyw:
			mov [WANTED_DIRECTION],1
			jmp .moveend

		.keya:
			mov [WANTED_DIRECTION],2
			jmp .moveend

		.keys:
			mov [WANTED_DIRECTION],3
			jmp .moveend

		.keye:
			call growsnake
			jmp .moveend

		
		.keyp:
			mov ah,0
			int 0x16
			
			jmp .moveend
	
	.moveend:

	inc [MOVEMENT_COUNTER]

	cmp [MOVEMENT_COUNTER],MOVEMENT_COUNT_THRESHOLD
	jb .endsnakemove


	; this happens when the movement counter hits

	mov [MOVEMENT_COUNTER],0 ; reset movement countdown

	;call randomizeapple


	;inc [SNAKE_HEAD_OFFSET]
	;mov bx,[SNAKE_HEAD_OFFSET]



	mov ax,[SNAKE_HEAD_OFFSET]
	mov bx,2
	mul bx
	mov bx,ax


	push [SNAKE_ARRAY_START + bx] ; current position
	;call growsnake
	inc [SNAKE_HEAD_OFFSET]

	; because i dont know how to do modulos in asm
	;mov ax,[SNAKE_HEAD_OFFSET]
	;cmp ax,[SNAKE_LENGTH]
	;jne .dont_loop
	;sub ax,[SNAKE_LENGTH]

	;.dont_loop:
	;mov [SNAKE_HEAD_OFFSET],ax

	;inc [SNAKE_LENGTH]
	xor dx,dx
	mov ax,[SNAKE_HEAD_OFFSET]
	mov bx,[SNAKE_LENGTH]
	div bx ; 16 bit div divides dx:ax by (here) bx, puts the result in ax and the remainder (modulo for us) in dx

	mov [SNAKE_HEAD_OFFSET],dx


	mov ax,[SNAKE_HEAD_OFFSET]
	mov bx,2
	mul bx
	mov bx,ax

	pop [SNAKE_ARRAY_START + bx] ; current position

	mov al,[WANTED_DIRECTION]
	;cmp al,[SNAKE_DIRECTION]
	sub al,[SNAKE_DIRECTION]
	
	cmp al,2
	je .nosetdirection
	cmp al,-2
	je .nosetdirection

	
	mov al,[WANTED_DIRECTION]
	mov [SNAKE_DIRECTION],al
	.nosetdirection:

	;mov [SNAKE_DIRECTION],al

	;jg .albigger; al is bigger
	;jl .alsmaller; al is smaller
	;
	;jmp .nosetdirection ; equal so it doesnt matter
    ;
	;.albigger:
	;	sub al,[SNAKE_DIRECTION]
	;	cmp al,2
	;	je .nosetdirection
	;	jmp .setdirection
	;	
	;.alsmaller:
	;	sub [SNAKE_DIRECTION],al
	;	cmp [SNAKE_DIRECTION],2
	;	je .nosetdirection
	;	jmp .setdirection
    ;
	;.setdirection:
	;mov [SNAKE_DIRECTION],al
	;.nosetdirection:
	

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
		jmp .checkoutofbounds
	.movup:
		dec [SNAKE_ARRAY_START+1 + bx]
		jmp .checkoutofbounds
	.movleft:
		dec [SNAKE_ARRAY_START + bx]
		jmp .checkoutofbounds
	.movdown:
		inc [SNAKE_ARRAY_START+1 + bx]
		jmp .checkoutofbounds

	.checkoutofbounds:

	cmp [SNAKE_ARRAY_START + bx],GAME_WIDTH ; if snake is out of bounds
	jge killsnake ; jmp if not greater than or equal

	cmp [SNAKE_ARRAY_START+1 + bx],GAME_HEIGHT ; if snake is out of bounds
	jge killsnake

	cmp [SNAKE_ARRAY_START + bx],0 ; if snake is out of bounds
	jl killsnake ; jmp if less than (not sure how it works with signed vs unsigned stuff but its working so)

	cmp [SNAKE_ARRAY_START+1 + bx],0 ; if snake is out of bounds
	jl killsnake
	
	; apple intersect code
	mov ax,[SNAKE_HEAD_OFFSET]
	mov bx,2
	mul bx
	mov bx,ax
	mov ax,[SNAKE_ARRAY_START + bx]
	cmp ax, [APPLE_POSITION]
	jne .dontextend

	call randomizeapple
	call growsnake

	.dontextend:
	jmp .endsnakemove
	.endsnakemove:

	mov ax,0
	.checkintersect:

	push ax
	mov cx,2
	mul cx

	mov bx,ax

	mov ax,[SNAKE_HEAD_OFFSET]
	mul cx

	cmp ax,bx
	je .checkcontinue

	mov cx,[SNAKE_ARRAY_START + bx]
	mov bx,ax
	mov dx,[SNAKE_ARRAY_START + bx]
	
	cmp cx,dx
	jne .checkconend
	;mov ax,0
	;mov bx,0
	;mov cx,15
	;mov dx,15
	;push 90
	;call rect
	;pop ax

	call killsnake

	
	jmp .checkconend


	.checkcontinue:
	;mov ax,0
	;mov bx,0
	;mov cx,15
	;mov dx,15
	;push 90
	;call rect
	;pop ax

	.checkconend:
	pop ax


	inc ax
	cmp ax,[SNAKE_LENGTH]
	je .endsnakecheck

	jmp .checkintersect
	.endsnakecheck:

	push 0

	mov si,[SNAKE_LENGTH]

	.snakedrawloop:
	cmp si,0
	jz .snakedrawend
	dec si

	call loadgridcoords
	cmp ax,GAME_WIDTH * GAME_SCALE
	jge .snakedrawloop
	cmp bx,GAME_WIDTH * GAME_SCALE
	jge .snakedrawloop

	mov cx,GAME_SCALE
	mov dx,GAME_SCALE

	add ax,GRID_SPACING
	add bx,GRID_SPACING

	sub cx,GRID_SPACING
	sub dx,GRID_SPACING

	;inc ax
	;inc bx
	;dec cx
	;dec dx
	call rect

	jmp .snakedrawloop
	.snakedrawend:



	pop ax

	mov ax,[APPLE_POSITION]
	mov bl,GAME_SCALE
	mul bl
	push ax
	mov ax,[APPLE_POSITION+1]
	mul bl
	mov bx,ax
	pop ax

	mov cx,GAME_SCALE
	mov dx,GAME_SCALE

	push 0x0c
	call rect
	pop ax

	call waitscreen ; will wait for screen to pause for a sec while the electron gun or whatever it is in an emulator resets
	call show ; super quick copy buffer in between reset


	jmp main

;times 510-($-$$) db 0
;db 0x55, 0xaa ; in order to make disk bootable
; sectors down here loaded by an interrupt at the start

random: ;stores random number in ax
	mov ax,[RANDSEED]
	mov bx,0x3490
	mul bx
	add ax,5324
	mov bx,0x9523
	mul bx

	push ax

	mov ax,[RANDSEED]
	mov bx,0x4325
	mul bx
	add ax,9237
	mov bx,0x1295
	mul bx

	pop bx
	xor ax,bx

	mov [RANDSEED],ax ; hopefully this number is pretty random
	ret

randomizeapple:
	;rdrand [APPLE_POSITION]
	call random

	mov ah,0
	mov bl,GAME_WIDTH
	div bl

	mov [APPLE_POSITION],ah ; modulo stored in ah after division

	call random

	mov ah,0
	mov bl,GAME_HEIGHT
	div bl

	mov [APPLE_POSITION+1],ah ; modulo stored in ah after division


	;mov [APPLE_POSITION],al ; modulo stored in ah after division

	;mov [APPLE_POSITION+1],al ; modulo stored in ah after division
	;inc [APPLE_POSITION]
	;inc [APPLE_POSITION+1]

	;rdrand ax ; puts random number in ax

	;mov [APPLE_POSITION],ah
	;mov [APPLE_POSITION+1],al
	
	ret

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
	inc word [SNAKE_LENGTH]
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
	;mov [SNAKE_ARRAY_START-2 + bx],0 ; just because
	mov [SNAKE_ARRAY_START + bx],cx

	pop bx

	dec bx
	jmp .growloop

	.growend:

	mov bx,[SNAKE_HEAD_OFFSET]
	mov ax,bx
	mov cx,2
	mul cx
	mov bx,ax 
	mov [SNAKE_ARRAY_START+2 + bx], GAME_WIDTH ; just moves the new position to 0,0 for now (will change later)
	mov [SNAKE_ARRAY_START+2 + bx+1], GAME_HEIGHT ; just moves the new position to 0,0 for now (will change later)

	ret

killsnake: ; we can make this functoin as fancy as we want because its outside of the 512 byte limit
	mov ax,0
	mov bx,0
	mov cx,50
	mov dx,50
	push 14
	call rect
	call show
	pop ax
	jmp $ ; fun way to kill the player
	
initvars:
	mov [MOVEMENT_COUNTER],0
	
	mov [SNAKE_HEAD_OFFSET],0
	
	mov [SNAKE_ARRAY_START],0
	mov [SNAKE_ARRAY_START+1],0
	
	
	mov [SNAKE_LENGTH],1
	mov [SNAKE_DIRECTION],0
	mov [WANTED_DIRECTION],0

	mov word [APPLE_POSITION],0

	call randomizeapple

	ret

%include "src/graphics.asm"

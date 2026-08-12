[BITS 16]
[org 0x7c00]

%define GAME_WIDTH 30 ; max 127
%define GAME_HEIGHT 20 ; max 127
%define GAME_SCALE 8
%define GRID_SPACING 0
%define MOVEMENT_COUNT_THRESHOLD 3


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
mov dh,0

; dl is initialized to whatever disk you are booting from
; which it will read from

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

	add ax, 320/2 - GAME_WIDTH/2 *  GAME_SCALE - GAME_SCALE/2 ; center grid
	add bx, 200/2 - GAME_HEIGHT/2 * GAME_SCALE - GAME_SCALE/2

	
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

	;mov bx,[WANTED_DIRECTION] ; bl should have buffer size (for input buffering)

	cmp [WANTED_DIRECTION+1],2 ; input buffered at a max of two
	jae .moveend

	cmp al,'d'
	;cmp al,'l'
	je .keyd

	cmp al,'w'
	;cmp al,'k'
	je .keyw

	cmp al,'a'
	;cmp al,'h'
	je .keya

	cmp al,'s'
	;cmp al,'j'
	je .keys

	cmp al,'e'
	je .keye

	cmp al,'p'
	je .keyp
	 
	 ; snake direction 0,1,2,3 corresponds to right,up,left,down

	jmp .moveend

		.keyd:
			
			;mov [WANTED_DIRECTION],0
			mov cl,[WANTED_DIRECTION+1]
			sal cl,1
			mov al,0
			sal al,cl
			or [WANTED_DIRECTION],al
			inc [WANTED_DIRECTION+1]
			jmp .moveend

		.keyw:
			;mov [WANTED_DIRECTION],1
			mov cl,[WANTED_DIRECTION+1]
			sal cl,1
			mov al,1
			sal al,cl
			or [WANTED_DIRECTION],al
			inc [WANTED_DIRECTION+1]
			jmp .moveend

		.keya:
			;mov [WANTED_DIRECTION],2
			mov cl,[WANTED_DIRECTION+1]
			sal cl,1
			mov al,2
			sal al,cl
			or [WANTED_DIRECTION],al
			inc [WANTED_DIRECTION+1]
			jmp .moveend

		.keys:
			;mov [WANTED_DIRECTION],3
			mov cl,[WANTED_DIRECTION+1]
			sal cl,1
			mov al,3
			sal al,cl
			or [WANTED_DIRECTION],al
			inc [WANTED_DIRECTION+1]
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

	;mov al,[WANTED_DIRECTION]
	mov ax,[WANTED_DIRECTION]
	cmp ah,0
	je .nosetdirection
	and al,0b00000011
	;cmp al,[SNAKE_DIRECTION]
	sub al,[SNAKE_DIRECTION]
	
	cmp al,2
	je .nosetdirection
	cmp al,-2
	je .nosetdirection

	
	mov al,[WANTED_DIRECTION]
	and al,0b00000011
	mov [SNAKE_DIRECTION],al

	shr [WANTED_DIRECTION],2 ; remove input from from queue
	dec [WANTED_DIRECTION+1]
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

	mov [endsnakeoutside],0
	
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

	call drawsnake

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
	add ax, 320/2 - GAME_WIDTH/2 *  GAME_SCALE - GAME_SCALE/2 ; center apple
	add bx, 200/2 - GAME_HEIGHT/2 * GAME_SCALE - GAME_SCALE/2
	call rect
	pop ax

	mov ax,20
	mov bx,20
	mov cx,20
	mov dx,20
	push [WANTED_DIRECTION+1]
	call rect
	pop ax


	call waitscreen ; will wait for screen to pause for a sec while the electron gun or whatever it is in an emulator resets
	call show ; super quick copy buffer in between reset


	jmp main

;times 510-($-$$) db 0
;db 0x55, 0xaa ; in order to make disk bootable
; sectors down here loaded by an interrupt at the start

endsnakeoutside: db 0

drawsnake:
	mov si,[SNAKE_HEAD_OFFSET]
	;mov di,0
	xor di,di


	;push si
	;mov ax,si
	;inc ax
	;call snakeindexmod
	;mov si,ax
    ;
	;sal si,1
	;mov ax,[SNAKE_ARRAY_START + si]
	;cmp ax,GAME_WIDTH
	;setge [endsnakeoutside]
    ;
	;pop si

	;mov si,[SNAKE_HEAD_OFFSET]


	;call loadgridcoords
	;
	;cmp ax,GAME_SCALE * GAME_WIDTH
	;
	;je .setout
	;jmp .nosetout
	;.setout:
	;mov word [endsnakeoutside],0
	;
	;jmp .setoutend

	;.nosetout:
	;mov word [endsnakeoutside],0

	;.setoutend:



	.snakedrawloop: ; do
	mov bx,si
	sal bx,1
	mov ah,[SNAKE_ARRAY_START + bx] ; x position
	cmp ah,GAME_WIDTH
	jge .snakedrawcontinue; greater than or equal to, meaning outside the board

	; code below is scary
	; it calculates the next and previous segment relative to current segment so we can draw it thin and stuff
	push si
	push di
	
	mov ax,si
	inc ax
	call snakeindexmod
	mov di,ax ; si for 1 and di for 2
	xor ax,ax ; set ax to zero for later
	sal si,1
	sal di,1
	mov bh,[SNAKE_ARRAY_START+si] ; x1
	mov bl,[SNAKE_ARRAY_START+di] ; x2
	cmp bh,bl
	sete al ; if x's are equal one in ax,otherwise zero
	add si,ax
	add di,ax ; check y's if x's are the same
	mov bh,[SNAKE_ARRAY_START+si] ; x/y1
	mov bl,[SNAKE_ARRAY_START+di] ; x/y2
	cmp bh,bl
	setg ah ; 1 if second segment is greater otherwise 0
	sal al,1 ; move x/y toggle to the left
	or al,ah ; 00 if the x is less in the next segment, 01 if greater, and 1x for y's 
	xor ah,ah

	pop di
	pop si

	push ax ; now the info in ax is saved in the stack

	; do it again but for previous segment instead of next
	push si
	push di
	
	mov ax,si
	dec ax ; decrement instead
	call snakeindexmod
	mov di,ax ; si for 1 and di for 0
	xor cx,cx ; set ax to zero for later
	sal si,1
	sal di,1
	mov bh,[SNAKE_ARRAY_START+si] ; x1
	mov bl,[SNAKE_ARRAY_START+di] ; x2
	cmp bh,bl
	sete cl ; if x's are equal one in ax,otherwise zero
	add si,cx
	add di,cx ; check y's if x's are the same
	mov bh,[SNAKE_ARRAY_START+si] ; x/y1
	mov bl,[SNAKE_ARRAY_START+di] ; x/y2
	cmp bh,bl
	setg ch ; 1 if second segment is greater otherwise 0
	sal cl,1 ; move x/y toggle to the left
	or cl,ch ; 00 if the x is less in the next segment, 01 if greater, and 1x for y's 
	xor ch,ch

	pop di
	pop si

	pop ax
	sal cx,2 ; shift cx bits to the left twice
	or ax,cx

	mov bp,ax

	call loadgridcoords
	
	mov cx,GAME_SCALE
	mov dx,GAME_SCALE
	
	; now a ton of cmps for how to draw the snake!!
	; so much fun writing this

	; TODO: stop
	add ax, 320/2 - GAME_WIDTH/2 *  GAME_SCALE - GAME_SCALE/2 ; center snake
	add bx, 200/2 - GAME_HEIGHT/2 * GAME_SCALE - GAME_SCALE/2

	cmp di,0
	je .frontdraw

	push ax
	xor ax,ax
	mov al,[endsnakeoutside]
	inc al
	cmp di,ax
	pop ax
	je .backdraw

	cmp bp,0x4
	je .straightdrawx

	cmp bp,0x1
	je .straightdrawx

	cmp bp,0xE
	je .straightdrawy

	cmp bp,0xB
	je .straightdrawy

	cmp bp,0xD
	je .benddrawleftup

	cmp bp,0x7
	je .benddrawleftup

	cmp bp,0x6
	je .benddrawleftdown

	cmp bp,0x9
	je .benddrawleftdown

	cmp bp,0x3
	je .benddrawrightup

	cmp bp,0xC
	je .benddrawrightup

	cmp bp,0x8
	je .benddrawrightdown

	cmp bp,0x2
	je .benddrawrightdown

	jmp .fallbackdraw

	.straightdrawx:
	sub dx,2
	inc bx
	push di
	call rect
	pop bp
	jmp .enddraw

	.straightdrawy:
	sub cx,2
	inc ax
	push di
	call rect
	pop bp
	jmp .enddraw

	.benddrawleftup:
	sub cx,2
	inc ax

	dec dx
	push di
	call rect
	pop bp
	inc dx

	add cx,2
	dec ax

	sub dx,2
	inc bx
	dec cx

	push di
	call rect
	pop bp
	jmp .enddraw

	.benddrawleftdown:
	sub cx,2
	inc ax

	inc bx
	dec dx

	push di
	call rect
	pop bp

	dec bx
	inc dx

	add cx,2
	dec ax

	sub dx,2
	inc bx
	dec cx

	push di
	call rect
	pop bp
	jmp .enddraw

	.benddrawrightup:
	sub cx,2
	inc ax

	dec dx


	push di
	call rect
	pop bp

	inc dx


	add cx,2
	dec ax

	sub dx,2
	inc bx

	inc ax
	dec cx
	push di
	call rect
	pop bp
	jmp .enddraw

	.benddrawrightdown:
	sub cx,2
	inc ax

	inc bx
	dec dx


	push di
	call rect
	pop bp

	inc dx
	dec bx


	add cx,2
	dec ax

	sub dx,2
	inc bx

	inc ax
	dec cx
	push di
	call rect
	pop bp
	jmp .enddraw

	.backdraw:
	;push bp
	;and bp,0b000000000000010

	;push bx
	;mov bx,0
	;cmp bp,0b000000000000010 ; if that bit is set

	;sete bl

	;add ax,bx
	;sub cx,bx
	;sub cx,bx
	;
	;pop bx

	;push ax
	;mov ax,0
	;cmp bp,0b000000000000010 ; if that bit is set

	;setne al

	;add bx,ax
	;sub dx,ax
	;sub dx,ax
	;
	;pop ax
	;pop bp

	;call rect

	;push ax
	;xor ax,ax
	;
	;bt bp,1 ; check second to last bit
    ;
	;setb al; puts cf into al (basically)
    ;
	;mov bp,ax
    ;
	;pop ax
    ;
	;add ax,bp
	;sub cx,bp
	;sub cx,bp
    ;
	;xor bp,1 ; boolean NOT operation (!bp)
    ;
	;add bx,bp
	;sub dx,bp
	;sub dx,bp
	;
	;; we've thinned the snake, but now we want the tail to be slightly shorter than a regular segment
    ;
	;push ax
	;xor ax,ax
    ;
	;bt bp,0
	;setb al
	;mov bp,ax
	;pop ax
    ;
	;sub cx,bp
	;add ax,bp
    ;
	;xor bp,1
    ;
	;sub cx,bp


	; oh boy another string of cmps
	and bp,0b0000000000000011

	cmp bp,0
	je .backdrawxright
	cmp bp,1
	je .backdrawxleft
	cmp bp,2
	je .backdrawydown
	cmp bp,3
	je .backdrawyup
	jmp .backdrawend

	.backdrawxleft:
	dec cx

	sub dx,2
	inc bx
		
	jmp .backdrawend
	.backdrawxright:
	inc ax
	dec cx

	sub dx,2
	inc bx

	jmp .backdrawend
	.backdrawyup:
	dec dx

	sub cx,2
	inc ax

	jmp .backdrawend
	.backdrawydown:
	inc bx
	dec dx

	sub cx,2
	inc ax

	jmp .backdrawend




	.backdrawend:
	push bp
	call rect
	pop bp



	jmp .enddraw

	.frontdraw:
	cmp [SNAKE_DIRECTION],0
	je .straightdrawx
	cmp [SNAKE_DIRECTION],1
	je .straightdrawy
	cmp [SNAKE_DIRECTION],2
	je .straightdrawx
	cmp [SNAKE_DIRECTION],3
	je .straightdrawy


	jmp .enddraw

	.fallbackdraw:
	and bp,0b0000010
	cmp bp,0b0000010
	push ax
	xor ax,ax
	setne al
	mov bp,ax
	pop ax
	
	add ax,bp
	sub cx,bp
	sub cx,bp
	
	push ax
	xor ax,ax
	mov al,[endsnakeoutside]
	mov bp,ax

	pop ax

	;push di
	push bp

	;push 123
	call rect
	pop bp

	.enddraw:


	.snakedrawcontinue: ; while
	inc si
	inc di

	mov ax,si
	call snakeindexmod
	mov si,ax
	mov bx,[SNAKE_HEAD_OFFSET]
	cmp si,bx
	je .snakedrawloopend
	jmp .snakedrawloop
	.snakedrawloopend:

	ret

snakeindexmod: ; put index in ax
	cmp ax,0xffff ; if it's been decremented from 0
	je .setlen
	xor dx,dx ; we all hate dx
	mov bx,[SNAKE_LENGTH]
	div bx
	mov ax,dx ; modulo in dx
	jmp .return

	.setlen:
	mov ax,[SNAKE_LENGTH]
	dec ax

	.return:
	ret

snakeindexconvert: ; put index in ax
	; (index + capacity - head) % capacity
	; (head + capacity - index) % capacity
	mov bx,[SNAKE_LENGTH]

	add bx,[SNAKE_HEAD_OFFSET]

	sub bx,ax ; now bx has the first part
	xor dx,dx
	mov ax,bx
	mov bx,[SNAKE_LENGTH]
	div bx

	mov ax,dx

	;add ax,bx
	;sub ax,[SNAKE_HEAD_OFFSET]
	;xor dx,dx
	;div bx
    ;
	;sub bx,dx
	;mov ax,bx
	;;mov ax,dx
	;dec ax
	ret
	

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
	mov [SNAKE_ARRAY_START+2 + bx], GAME_WIDTH
	mov [SNAKE_ARRAY_START+2 + bx+1], GAME_HEIGHT
	mov [endsnakeoutside],1

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
	
	mov word [SNAKE_HEAD_OFFSET],0
	
	mov [SNAKE_ARRAY_START],0
	mov [SNAKE_ARRAY_START+1],0
	
	
	mov word [SNAKE_LENGTH],1
	mov [SNAKE_DIRECTION],0
	mov word [WANTED_DIRECTION],0

	mov word [APPLE_POSITION],0

	call randomizeapple

	ret

%include "src/graphics.asm"

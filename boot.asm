[BITS 16]
[org 0x7c00]
; we have 510 bytes to use here (perfect for snake!)

mov ah, 0x0 ; set video mode
mov al, 0x13 ; video mode 0x13 (256 color)

int 0x10


mov ax,	0xA000 ; offset of base pointer for vga framebuffer
mov ds,	ax

mov ax,	0x0000
mov ss,	ax
mov sp,	0x7c00 ; set up stack pointer and stack offset to be below code (if it overflows it will do bad weird stuff though)

main:
	mov al,1
	call clearscr

	mov ax,320/2 - 100/2
	mov bx,200/2 - 75/2
	mov cx,100
	mov dx,75
	push 3
	call rect
	
	hlt ; wait for refresh (or something)
	jmp main

clearscr: ; clear color is in al register
	push bp
	mov bp,sp ; create stack frame
	
	mov bx,0xA000
	mov es,bx ; move vga framebuffer offset into extra segment register
	mov di,0x0 ; clear di (framebuffer starts at 0xA000 + 0 so)
	mov cx,320*200 ; how many bytes we want to set (the whole buffer)
	rep stosb ; do it

	mov sp,bp
	pop bp ; destroy stack frame
	ret

line: ; ax for x, bx for y, cx for width, stack for color (will stay on stack on return)
	push bp
	mov bp,sp ; create stack frame

	push ax
	push bx
	push cx
	push dx

	push ax ; save x coordinate

	mov ax,0xA000
	mov es,ax ; put framebuffer offset into extra segment

	mov ax,320 ; put screen width in ax
	mul bx ; multiply bx (row) by ax (screen width) and store it in ax
	pop bx ; pop x coordinate into bx
	add ax,bx ; adds bx (x coordinate) to ax (so now ax has the index of the start of the line)

	mov di,ax ; put index into di for rep stosb

	mov al,[bp+4] ; accesses pushed value beforehand for 
	cld ; make sure this counts in the correct direction
	rep stosb ; should count down through cx which is already there (we never changed it)

	pop dx
	pop cx
	pop bx
	pop ax

	mov sp,bp
	pop bp ; destroy stack frame
	ret

rect: ; ax for x, bx for y, cx for width, dx for height, stack for color
	push bp
	mov bp,sp ; create stack frame

	push ax ; keep registers the same after call
	push bx
	push cx
	push dx

	push [bp+4] ; pushes color in stack onto the top of the stack

.rectloop:
	cmp dx,0
	je .rectend
	dec dx

	call line
	inc bx
	jmp .rectloop

.rectend:

	pop dx ; just get the top bit off
	pop dx
	pop cx
	pop bx
	pop ax

	mov sp,bp
	pop bp ; destroy stack frame
	ret


times 510-($-$$) db 0
db 0x55, 0xaa ; in order to make disk bootable

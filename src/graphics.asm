init:
	mov ah, 0x0 ; set video mode
	mov al, 0x13 ; video mode 0x13 (256 color)
	int 0x10

	ret

clearscr: ; clear color is in al register
	push bp
	mov bp,sp ; create stack frame

	push bx
	push cx
	push dx
	
	mov bx,0xA000
	mov es,bx ; move vga framebuffer offset into extra segment register
	mov di,0x0 ; clear di (framebuffer starts at 0xA000 + 0 so)
	mov cx,320*200 ; how many bytes we want to set (the whole buffer)
	rep stosb ; do it

	pop dx
	pop cx
	pop bx

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



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

call _clear

mov bx, 0x0
mov cx, 0x1

main:
	mov [ds:bx],cx
	inc bx
	call _check_screen_end


	mov ah, 0x86 ; wait interrupt
	push cx
	push dx ; to get back later after passing params
	mov cx,0x0
	;mov dx,16000 ; 16 ms delay (~60fps)
	mov dx,1

	;int 0x15

	times 20 nop

	pop dx
	pop cx

	jmp main

_check_screen_end:
	cmp bx,320*200
	ja _reset_screen_fill; jump if above screen bounds
	ret

_reset_screen_fill:
	xor bx,bx
	inc cx
	ret

_clear:
	mov bx,320*200
	jmp _clear_loop

_clear_loop:
	dec bx
	mov [bx], 50 ; automatically use ds pointer as offset
	cmp bx, 0
	je _clear_end
	jmp _clear_loop

_clear_end:
	ret

times 510-($-$$) db 0
db 0x55, 0xaa

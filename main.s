	.include	"syscalls.s"
.data
newline:.asciz	"\n"
msg_width:	.asciz 	"width: "
msg_height:	.asciz "height: "
msg_pixel:	.asciz	"pixel address on the heap: "
msg_stride:	.asciz	"stride: "
msg_sign:	.asciz	"height's sign: "
.text
main:
	lw	s11, 0(a1)
	
	li	a0, SCREEN_WIDTH
	slli	a0, a0, 9	# width * height
	slli	a0, a0, 2	# width * height * 4 bytes
	li	a7, SYS_SBRK
	ecall
	
	mv	a0, s11
	jal	load_bmp_pixels
	
	bnez	a0, fin
	
	mv	s0, a1		# pixel address on heap
	mv	s1, a2		# width
	mv	s2, a3		# height
	mv	s3, a4		# stride
	mv	s4, a5		# heigh's sign
	
	la	a0, msg_pixel
	li	a7, SYS_PRINT_STR	# print pixel address info
	ecall
	mv	a0, s0
	li	a7, SYS_PRINT_INT
	ecall
	la	a0, newline
	li	a7, SYS_PRINT_STR
	ecall
	
	la	a0, msg_width
	li	a7, SYS_PRINT_STR	# print width info
	ecall
	mv	a0, s1
	li	a7, SYS_PRINT_INT
	ecall
	la	a0, newline
	li	a7, SYS_PRINT_STR
	ecall
	
	la	a0, msg_height
	li	a7, SYS_PRINT_STR	# print height info
	ecall
	mv	a0, s2
	li	a7, SYS_PRINT_INT
	ecall
	la	a0, newline
	li	a7, SYS_PRINT_STR
	ecall
	
	la	a0, msg_stride
	li	a7, SYS_PRINT_STR	# print stride info
	ecall
	mv	a0, s3
	li	a7, SYS_PRINT_INT
	ecall
	la	a0, newline
	li	a7, SYS_PRINT_STR
	ecall
	
	la	a0, msg_sign
	li	a7, SYS_PRINT_STR	# print info about height's sign
	ecall
	mv	a0, s4
	li	a7, SYS_PRINT_INT
	ecall
	la	a0, newline
	li	a7, SYS_PRINT_STR
	ecall
	
	jal	draw_image
	
fin:
	li	a7, SYS_EXIT0		# end the program
	ecall	
	
	
	

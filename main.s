	.include	"syscalls.s"
.data
newline:.asciz	"\n"
msg_w:	.asciz 	"width: "
msg_h:	.asciz "height: "
msg_p:	.asciz	"pixel address on the heap: "
msg_s:	.asciz	"stride: "

.text
main:
	jal	load_bmp_pixels
	
	bnez	a0, fin
	
	la	a0, msg_p
	li	a7, SYS_PRINT_STR	# print pixel address info
	ecall
	mv	a0, a0
	li	a7, SYS_PRINT_INT
	ecall
	la	a0, newline
	li	a7, SYS_PRINT_STR
	ecall
	
	la	a0, msg_w
	li	a7, SYS_PRINT_STR	# print width info
	ecall
	mv	a0, a2
	li	a7, SYS_PRINT_INT
	ecall
	la	a0, newline
	li	a7, SYS_PRINT_STR
	ecall
	
	la	a0, msg_h
	li	a7, SYS_PRINT_STR	# print height info
	ecall
	mv	a0, a3
	li	a7, SYS_PRINT_INT
	ecall
	la	a0, newline
	li	a7, SYS_PRINT_STR
	ecall
	
	la	a0, msg_s
	li	a7, SYS_PRINT_STR	# print stride info
	ecall
	mv	a0, a4
	li	a7, SYS_PRINT_INT
	ecall
	la	a0, newline
	li	a7, SYS_PRINT_STR
	ecall
	
fin:
	li	a7, SYS_EXIT0		# end the program
	ecall	
	
	
	

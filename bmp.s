	.include	"syscalls.s"
	.globl		read_bmp_metadata
.data
filename:	.asciz	"cr7.bmp"
msg_open_err:	.asciz	"File was not opened!"
msg_read_err:	.asciz	"File was opened but not read!"
.text
read_bmp_metadata:
	addi	sp, sp, -32
	sw	ra, 28(sp)
	sw	s0, 24(sp)
	sw	s1, 20(sp)
	sw	s2, 16(sp)
	sw	s3, 12(sp)
	sw	s4, 8(sp)

	li	a0, BYTES_TO_ALLOCATE	# allocate 58 bytes on the heap for BMP header, because of the starting address alignment
	li	a7, SYS_SBRK
	ecall

	addi	t0, a0, 3		# prepare address for 4 byte alignment
	andi	s0, t0, -4		# round address down to nearest multiple of 4

	la	a0, filename
	mv	a1, zero	# read-only operation
	li	a7, SYS_OPEN_FILE
	ecall

	li	t0, -1
	beq	a0, t0, file_open_error	# if a0 == -1 - file was not opened

	mv	s1, a0		# s1 contains file descriptor

	mv	a0, s1		# a0 - file descriptor
	mv	a1, s0		# a1 - bufor's address, where the bytes should be stored
	li	a2, BMP_HEADER_SIZE	# a2 - number of bytes we want to store
	li	a7, SYS_READ_FILE	# a7 - read file
	ecall

	li	t0, BMP_HEADER_SIZE
	blt	a0, t0, file_read_error	# if we read less bytes than expected - we did not read the whole file

	mv	a0, s1
	li	a7, SYS_CLOSE_FILE
	ecall

	lhu	t0, 18(s0)	# lower 16 bits
	lhu	t1, 20(s0)	# upper 16 bits
	slli	t1, t1, 16	# shift upper 16 bits to the left
	or	s2, t0, t1	# load the whole width to s2

	lhu	t0, 22(s0)	# lower 16 bits
	lhu	t1, 24(s0)	# upper 16 bits
	slli	t1, t1, 16	# shift upper 16 bits to the left
	or	s3, t0, t1	# load the whole height to s3

	lhu	t0, 10(s0)	# pixel data offset is on the 10th position
	lhu	t1, 12(s0)
	slli	t1, t1, 16
	or	s4, t0, t1	# pixel data offset

	mv	a0, zero	# code 0 - there is no error
	mv	a1, s2		# return width
	mv	a2, s3		# return height
	mv	a3, s4		# return pixel data
	j	epilogue

file_open_error:
	la	a0, msg_open_err	# print the message about error
	li	a7, SYS_PRINT_STR
	ecall
	li	a0, -1			# return -1 - code of open error
	j	epilogue

file_read_error:
	mv	a0, s1
	li	a7, SYS_CLOSE_FILE	# close file anyway - despite not reading the whole file
	ecall

	la	a0, msg_read_err	# print the message about error
	li	a7, SYS_PRINT_STR
	ecall
	li	a0, -2			# return -2 - code of read error

epilogue:
	lw	s4, 8(sp)
	lw	s3, 12(sp)
	lw	s2, 16(sp)
	lw	s1, 20(sp)
	lw	s0, 24(sp)
	lw	ra, 28(sp)
	addi	sp, sp, 32
	ret
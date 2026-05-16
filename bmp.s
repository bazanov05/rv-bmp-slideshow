	.include	"syscalls.s"
	.globl		load_bmp_pixels
.data
msg_open_err:	.asciz	"File was not opened!"
msg_read_err:	.asciz	"File was opened but the header was not read!"
msg_pixel_err:	.asciz	"Pixels were not read!"
.text
load_bmp_pixels:
	addi	sp, sp, -48
	sw	ra, 44(sp)	# return address
	sw	s0, 40(sp)	# address on heap
	sw	s1, 36(sp)	# file descriptor 
	sw	s2, 32(sp)	# width
	sw	s3, 28(sp)	# height
	sw	s4, 24(sp)	# pixel pic on heap
	sw	s5, 20(sp)	# stride
	sw	s6, 16(sp)	# flag for height's sign
	sw	s7, 12(sp)	# filename from main.s
	
	mv	s7, a0		# s7 now contains file name
	
	li	a0, BYTES_TO_ALLOCATE	# allocate 58 bytes on the heap for BMP header, because of the starting address alignment
	li	a7, SYS_SBRK
	ecall

	addi	t0, a0, 3		# prepare address for 4 byte alignment
	andi	s0, t0, -4		# round address down to nearest multiple of 4

	mv	a0, s7
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

	lhu	t0, 18(s0)	# lower 16 bits
	lhu	t1, 20(s0)	# upper 16 bits
	slli	t1, t1, 16	# shift upper 16 bits to the left
	or	s2, t0, t1	# load the whole width to s2

	lhu	t0, 22(s0)	# lower 16 bits
	lhu	t1, 24(s0)	# upper 16 bits
	slli	t1, t1, 16	# shift upper 16 bits to the left
	or	s3, t0, t1	# load the whole height to s3
	
	mv	s6, zero	# height is positive
	bgtz	s3, height_is_positive
	
	sub	s3, zero, s3 	# abs(height)
	li	s6, 1		# height is negative

height_is_positive:
	lhu	t0, 10(s0)	# pixel data offset is on the 10th position
	lhu	t1, 12(s0)
	slli	t1, t1, 16
	or	s4, t0, t1	# pixel data offset

	j	allocate_memory_for_pic

allocate_memory_for_pic:
	jal	calculate_stride
	
	mul	t1, s3, s5		# pic's size in bytes
	
	mv	a0, t1
	li	a7, SYS_SBRK		# allocate memory on heap for pixels
	ecall
	
	mv	s0, a0		# address on heap where pixels start
	
	mv	a0, s1		# file descriptor
	mv	a1, s4		# offset of pixel data
	mv	a2, zero	# offset relative to the beginning of the file
	li	a7, SYS_LSEEK
	ecall
	
	mv	a0, s1		# file descriptor
	mv	a1, s0		# where the bytes begin on the heap
	mv	a2, t1		# the pic size
	li	a7, SYS_READ_FILE
	ecall
	
	blt	a0, t1, file_pixel_error	# if we read less bytes then expected - there is an error
	
	mv	a0, s1
	li	a7, SYS_CLOSE_FILE
	ecall
	
	mv	a0, zero	# error code - no error
	mv	a1, s0		# address of pixels on the heap
	mv	a2, s2		# width
	mv	a3, s3		# height
	mv	a4, s5		# stride
	mv	a5, s6		# height's sign
	
epilogue:
	lw	s7, 12(sp)
	lw	s6, 16(sp)
	lw	s5, 20(sp)
	lw	s4, 24(sp)
	lw	s3, 28(sp)
	lw	s2, 32(sp)
	lw	s1, 36(sp)
	lw	s0, 40(sp)
	lw	ra, 44(sp)
	addi	sp, sp, 48
	
	ret
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
	j	epilogue

file_pixel_error:
	mv	a0, s1
	li	a7, SYS_CLOSE_FILE	# close file anyway - despite not reading the whole file
	ecall

	la	a0, msg_pixel_err	# print the message about error
	li	a7, SYS_PRINT_STR
	ecall
	li	a0, -3			# return -3 - code of read pixel error
	j 	epilogue

calculate_stride:
	mv	t0, s2
	slli	t1, t0, 1
	add	t1, t1, t0	# width * 3 - how many bytes we need per one row
	
	addi	t1, t1, 3	# prepare num on bytes for 4 alighment
	andi	s5, t1, -4	# s5 - stride 
	
	ret
	
	

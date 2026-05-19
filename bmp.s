	.include	"syscalls.s"
	.globl		load_bmp_pixels
.data
msg_open_err:	.asciz	"File was not opened!"
msg_read_err:	.asciz	"File was opened but the header was not read!"
msg_pixel_err:	.asciz	"Pixels were not read!"
.text
load_bmp_pixels:
	addi	sp, sp, -16
	sw	ra, 0(sp)	# return address
	sw	s0, 4(sp)	# buffor address (for pic data)
	sw	s1, 8(sp)	# file descriptor
	sw	s2, 12(sp)	# the address of header on the heap
	
	mv	a6, a0		# a6 now contains file name
	mv	s0, a1		# in a1 we have the address of buffor for pic data
	
	li	a0, BYTES_TO_ALLOCATE	# allocate 58 bytes on the heap for BMP header, because of the starting address alignment
	li	a7, SYS_SBRK
	ecall

	addi	t0, a0, 3		# prepare address for 4 byte alignment
	andi	s2, t0, -4		# round address down to nearest multiple of 4

	mv	a0, a6
	mv	a1, zero	# read-only operation
	li	a7, SYS_OPEN_FILE
	ecall

	li	t0, -1
	beq	a0, t0, file_open_error	# if a0 == -1 - file was not opened

	mv	s1, a0		# s1 contains file descriptor

	mv	a0, s1		# a0 - file descriptor
	mv	a1, s2		# a1 - bufor's address, where the bytes should be stored
	li	a2, BMP_HEADER_SIZE	# a2 - number of bytes we want to store
	li	a7, SYS_READ_FILE	# a7 - read file
	ecall

	li	t0, BMP_HEADER_SIZE
	blt	a0, t0, file_read_error	# if we read less bytes than expected - we did not read the whole file

	lhu	t0, 18(s2)	# lower 16 bits
	lhu	t1, 20(s2)	# upper 16 bits
	slli	t1, t1, 16	# shift upper 16 bits to the left
	or	t0, t0, t1	# whole width
	sw	t0, 4(s0)	# store the width in our buffor for pic data

	lhu	t0, 22(s2)	# lower 16 bits
	lhu	t1, 24(s2)	# upper 16 bits
	slli	t1, t1, 16	# shift upper 16 bits to the left
	or	t0, t0, t1	# whole height
	sw	t0, 8(s0)	# store the height
	
	mv	t6, zero	# height is positive
	sw	t6, 16(s0)
	bgtz	t0, height_is_positive
	
	sub	t0, zero, t0	# abs(height)
	sw	t0, 8(s0)	# store the positive height now
	li	t6, 1		# height is negative
	sw	t6, 16(s0)

height_is_positive:
	lhu	t0, 10(s2)	# pixel data offset is on the 10th position
	lhu	t1, 12(s2)
	slli	t1, t1, 16
	or	t4, t0, t1	# pixel data offset
	
allocate_memory_for_pic:
	lw	a0, 4(s0)	# load width to calculate stride
	jal	calculate_stride
	
	sw	a0, 12(s0)	# store the stride
	
	lw	a1, 8(s0)
	mul	a0, a0, a1		# pic's size in bytes
	mv	t5, a0		# t5 now holds the pic size in bytes
	
	mv	a0, t5
	li	a7, SYS_SBRK		# allocate memory on heap for pixels
	ecall
	
	sw	a0, 0(s0)		# address on heap where pixels start
	
	mv	a0, s1		# file descriptor
	mv	a1, t4 		# offset of pixel data
	mv	a2, zero	# offset relative to the beginning of the file
	li	a7, SYS_LSEEK
	ecall
	
	mv	a0, s1		# file descriptor
	lw	a1, 0(s0)		# where the bytes begin on the heap
	mv	a2, t5		# the pic size
	li	a7, SYS_READ_FILE
	ecall
	
	blt	a0, t5, file_pixel_error	# if we read less bytes then expected - there is an error
	
	mv	a0, s1
	li	a7, SYS_CLOSE_FILE
	ecall
	
	mv	a0, zero	# success code - no errors were found
		
epilogue:
	lw	s2, 12(sp)
	lw	s1, 8(sp)
	lw	s0, 4(sp)
	lw	ra, 0(sp)
	addi	sp, sp, 16
	
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
	mv	t0, a0
	slli	t1, t0, 1
	add	t1, t1, t0	# width * 3 - how many bytes we need per one row
	
	addi	t1, t1, 3	# prepare num on bytes for 4 alighment
	andi	a0, t1, -4	# a0 - stride, ret argument
	
	ret
	
	

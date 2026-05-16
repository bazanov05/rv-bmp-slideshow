	.include	"syscalls.s"
.data
step:	.word	0
cx1:	.word	0	# center_x for pic1
cy1:	.word	0	# center_y for pic1
cx2:	.word	0
cy2:	.word	0
swap_done:	.byte	0	# flag - to chceck if the swap between pics was done
.text
main:
	lw	s11, 0(a1)	# first file name
	lw	s10, 4(a1)	# second file name
	
	li	a0, SCREEN_WIDTH
	slli	a0, a0, 9	# width * height
	slli	a0, a0, 2	# width * height * 4 bytes
	li	a7, SYS_SBRK	# save place on the heap for screen
	ecall
	
	mv	a0, s11		# get 1st file data
	jal	load_bmp_pixels
	
	bnez	a0, fin
	
	mv	s0, a1		# 1st pixel address on heap
	mv	s1, a2		# 1st width
	mv	s2, a3		# 1st height
	mv	s3, a4		# 1st stride
	mv	s4, a5		# 1st height's sign
	
	mv	a0, s10		# get 2nd file data
	jal	load_bmp_pixels
	
	bnez	a0, fin
	
	mv	s5, a1		# 2nd pixel address on heap
	mv	s6, a2		# 2nd width
	mv	s7, a3		# 2nd height
	mv	s8, a4		# 2nd stride
	mv	s9, a5		# 2nd height's sign
	
	mv	a0, s1
	jal	calculate_x_offset
	la	t0, cx1
	sw	a0, 0(t0)		
	
	mv	a0, s2
	jal	calculate_y_offset
	la	t0, cy1
	sw	a0, 0(t0)		
	
	mv	a0, s6
	jal	calculate_x_offset
	la	t0, cx2
	sw	a0, 0(t0)
	
	mv	a0, s7
	jal	calculate_y_offset
	la	t0, cy2
	sw	a0, 0(t0)	
	
animation_loop:
	la	t0, step
	sw	zero, 0(t0)	# reset step before next drawning 
	
slide_loop:
	jal	clear_screen	# clean the screen before every loop so on the screen there will be no old drawings
	la	t0, cx1
	la	t1, step
	lw	t2, 0(t0)
	lw	t3, 0(t1)
	sub	a6, t2, t3	# x_curr = x_center - offset
	
	la	t0, cy1
	lw	a7, 0(t0)
	
	mv	a1, s0		# pixel address
	mv	a2, s1		# pic's width
	mv	a3, s2		# pic's height
	mv	a4, s3		# pic's stride
	mv	a5, s4		# height's sigh
	
	jal	draw_image	# draw the first pic
	
	la	t0, cx2
	la	t1, step
	lw	t2, 0(t0)
	lw	t3, 0(t1)
	sub	a6, t2, t3	# x_curr = x_center - offset
	addi	a6, a6, SCREEN_WIDTH	# x_curr = x_center - offset + 512 , 2nd pic starts from the right
	
	la	t0, cy2
	lw	a7, 0(t0)
	
	mv	a1, s5		# pixel address
	mv	a2, s6		# pic's width
	mv	a3, s7		# pic's height
	mv	a4, s8		# pic's stride
	mv	a5, s9		# height's sigh
	
	jal	draw_image
	
	li	a0, 2		# sleep for 2 ms
	li	a7, SYS_SLEEP
	ecall
	
	la	t0, step
	lw	t3, 0(t0)
	addi	t3, t3, 128	# incr step
	sw	t3, 0(t0)
	
	li	t4, SCREEN_WIDTH
	ble	t3, t4, slide_loop
	
	la	t0, swap_done
	lbu	t1, 0(t0)
	bnez	t1, fin		# if the swap was done - end the program 
	
	addi	t1, t1, 1
	sb	t1, 0(t0)
	
	li	a0, 2000	# sleep for 2000 ms
	li	a7, SYS_SLEEP
	ecall
	
swap:
	mv	t0, s0
	mv	s0, s5
	mv	s5, t0		# swap pixel addresses
	
	mv	t0, s1
	mv	s1, s6
	mv	s6, t0		# swap width

	mv	t0, s2
	mv	s2, s7
	mv	s7, t0		# swap height

	mv	t0, s3
	mv	s3, s8
	mv	s8, t0		# swap stride

	mv	t0, s4
	mv	s4, s9
	mv	s9, t0		# swap sign's

	la	t0, cx1
	lw	t1, 0(t0)
	la	t2, cx2
	lw	t3, 0(t2)
	sw	t3, 0(t0)
	sw	t1, 0(t2)	# swap x_center

	la	t0, cy1
	lw	t1, 0(t0)
	la	t2, cy2
	lw	t3, 0(t2)
	sw	t3, 0(t0)
	sw	t1, 0(t2)	# swap y_center
	
	j	animation_loop
fin:
	li	a7, SYS_EXIT0		# end the program
	ecall	
	
calculate_y_offset:
	li	t0, SCREEN_HEIGHT
	sub	t0, t0, a0	# screen height - pic height
	srli	t0, t0, 1	# (screen height - pic height) / 2
	
	mv	a0, t0
	ret
	
calculate_x_offset:
	li	t0, SCREEN_WIDTH
	sub	t0, t0, a0	# screen width - pic width
	srli	t0, t0, 1	# (screen width - pic width) / 2
	
	mv	a0, t0
	ret

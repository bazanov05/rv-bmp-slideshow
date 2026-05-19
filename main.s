	.include	"syscalls.s"
.data
step:	.word	0
cx1:	.word	0
cy1:	.word	0
cx2:	.word	0
cy2:	.word	0
pic1:	.space	28	# 7 parameters - pixel address, width, height, stride, height's sign, x_begin, y_begin
pic2:	.space	28
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
	la	a1, pic1
	jal	load_bmp_pixels
	
	bnez	a0, fin
	
	mv	a0, s10		# get 2nd file data
	la	a1, pic2
	jal	load_bmp_pixels
	
	bnez	a0, fin
	
	la	t0, pic1
	lw	a0, 4(t0)
	jal	calculate_x_offset
	la	t0, cx1
	sw	a0, 0(t0)		
	
	la	t0, pic1
	lw	a0, 8(t0)
	jal	calculate_y_offset
	la	t0, cy1
	sw	a0, 0(t0)		
	
	la	t0, pic2
	lw	a0, 4(t0)
	jal	calculate_x_offset
	la	t0, cx2
	sw	a0, 0(t0)		
	
	la	t0, pic2
	lw	a0, 8(t0)
	jal	calculate_y_offset
	la	t0, cy2
	sw	a0, 0(t0)	
	
animation_loop:
	la	t0, step
	sw	zero, 0(t0)	# reset step before next drawing 
	
slide_loop:

	jal	clear_screen	# clean the screen before every loop

	la	t0, cx1
	la	t1, step
	lw	t2, 0(t0)
	lw	t3, 0(t1)
	sub	t4, t2, t3	# x_curr = x_center - step

	la	t0, pic1
	sw	t4, 20(t0)	# update x_begin inside the struct for pic1

	
	la	t0, cy1
	lw	t4, 0(t0)	# we always have height's alignment (y)
	la	t0, pic1
	sw	t4, 24(t0)	# update y_begin inside the struct for pic1

	la	a0, pic1	# pass address of the pic1 struct
	jal	draw_image	# draw the first pic


	la	t0, cx2
	la	t1, step
	lw	t2, 0(t0)
	lw	t3, 0(t1)
	sub	t4, t2, t3	
	addi	t4, t4, SCREEN_WIDTH	# x_curr = x_center - step + 512 (starts from the right)

	
	la	t0, pic2
	sw	t4, 20(t0)	# update x_begin inside the struct for pic2

	la	t0, cy2
	lw	t4, 0(t0)
	la	t0, pic2
	sw	t4, 24(t0)	# update y_begin inside the struct for pic2

	la	a0, pic2	# pass address of the pic2 struct
	jal	draw_image


	li	a0, 20		# sleep for 20 ms
	li	a7, SYS_SLEEP

	ecall

	

	la	t0, step
	lw	t3, 0(t0)
	addi	t3, t3, 128	# incr step by 128 (1/4 of the screen)
	sw	t3, 0(t0)

	
	li	t4, SCREEN_WIDTH
	ble	t3, t4, slide_loop

	
	la	t0, swap_done
	lbu	t1, 0(t0)
	bnez	t1, fin		# if the swap was done - end the program 

	addi	t1, t1, 1
	sb	t1, 0(t0)

	

swap:

	la	t0, pic1
	la	t1, pic2
	li	t2, 5		# counter for 5 words, there is no need to swap x and y because loop will overwrite em

	

swap_struct_loop:
	lw	t3, 0(t0)	# load word from pic1
	lw	t4, 0(t1)	# load word from pic2
	sw	t4, 0(t0)	# store pic2 word into pic1
	sw	t3, 0(t1)	# store pic1 word into pic2

	addi	t0, t0, 4	# move to next word
	addi	t1, t1, 4

	addi	t2, t2, -1	# decr counter

	bnez	t2, swap_struct_loop

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

	

	li	a0, 2000	# sleep for 2000 ms before reverse animation
	li	a7, SYS_SLEEP
	ecall
	
	j	animation_loop

fin:

	li	a7, SYS_EXIT0	# end the program
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

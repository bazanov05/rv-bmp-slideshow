	.include	"syscalls.s"
	.globl		draw_image
.text
draw_image:
	addi	sp, sp, -48
	sw	ra, 44(sp)
	sw	s0, 40(sp)	# x offset
	sw	s1, 36(sp)	# y offset
	
	mv	s2, a2		# pic width
	mv	s3, a3		# pic height
	mv	s4, a4		# stride
	mv	s5, a5		# height's sign
	mv	s6, a1		# pixel offset
	
	sw	s2, 32(sp)
	sw	s3, 28(sp)
	sw	s4, 24(sp)
	sw	s5, 20(sp)
	sw	s6, 16(sp)
	sw	s7, 12(sp)
		
	jal	calculate_pic_offsets
	
	mv	s7, s3		# outer loop counter - height
	
	add	t1, s1, s3
	addi	t1, t1, -1	# start from bottom, in t1 i have curr_y
	li	t2, -1		# in t2 i have a loop step - if we start on bottom we should incr
	li   t0, 0x10040000      # load base heap address
	
	beqz	s5, outer_loop	# if the sigh on height is positive - start drawing from bottom 
	
	mv	t1, s1		# if the height is negative - draw from top
	li	t2, 1		# step is 1 - incr

outer_loop:
	mv	t3, t1		# the address of current row
	mv	t4, s0		# x_curr = x_offset 
	mv	t5, s2		# counter for inner loop is width - how many pixels we should draw in this row
	mv	t6, s6		# save old pixel addres, so after reading one row add stride to it to come to a new one
	
inner_loop:
	lbu	a0, 0(s6)	# blue
	lbu	a1, 1(s6)	# green
	lbu	a2, 2(s6)	# red
	
	slli	a2, a2, 16
	slli	a1, a1, 8
	
	or	a0, a0, a1
	or	a0, a0, a2	# change BGR format to RGB
	
	
	addi	s6, s6, 3	# go to next 3 bytes to read next pixel
	 
	slli	a7, t1, 9      	# a7 = y * 512
	add	a7, a7, t4      # a7 = (y * 512) + x
	slli	a7, a7, 2       # a7 = ((y * 512) + x) * 4 
	
	add	a7, a7, t0      # a7 = base address + offset
	
	sw	a0, 0(a7)       # show pixel on the screen
	
	addi	t5, t5, -1
	addi	t4, t4, 1	# go to next pixel
	
	bnez	t5, inner_loop
	
	add	t6, t6, s4	# add to current pixel address stride to come to new row
	mv	s6, t6		# update pixel start
	
	add	t1, t1, t2	# update row - eithet incr or decr(depending on t2, which step based on sheight sign)

	addi	s7, s7, -1	# update the outer loop counter which is height
	
	bnez	s7, outer_loop
	
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
	
calculate_pic_offsets:
	li	t0, SCREEN_WIDTH
	sub	s0, t0, s2
	srli	s0, s0, 1
	
	li	t0, SCREEN_HEIGHT
	sub	s1, t0, s3
	srli	s1, s1, 1
	
	ret
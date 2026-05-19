	.include	"syscalls.s"
	.globl		draw_image
	.globl		clear_screen
.text
draw_image:
	lw	t0, 0(a0)	# pixel address on heap
	lw	a4, 20(a0)	# x_begin
	lw	a5, 4(a0)	# width
	lw	a6, 12(a0)	# stride
	lw	t1, 24(a0)	# y_begin - in the loops curr_y
	lw	t3, 8(a0)	# height - in the loops height_counter for outer_loop
	
	lw	a1, 16(a0)	# height's sign
	
	mv	a2, t1		# copy y_start
	li	a7, 0x10040000	# base heap address
	
	add	t1, t1, t3
	addi	t1, t1, -1	# curr_y = y_begin + height - 1
	li	t2, -1		# y_step = -1, because we start from the down
	
	beqz	a1, outer_loop	# if sign is positive - draw from the bottom
	
	mv	t1, a2
	li	t2, 1		# if not - draw from the top and y_step = 1

outer_loop:
	mv	t4, a4		# x_curr = x_begin 
	mv	t5, a5		# counter for inner loop is width - how many pixels we should draw in this row
	mv	t6, t0		# save old pixel addres, so after reading one row add stride to it to come to a new one
	
inner_loop:
	lbu	a0, 2(t0)	# red
	slli	a0, a0, 8
	lbu	a1, 1(t0)	# green
	or	a0, a0, a1
	slli	a0, a0, 8
	lbu	a1, 0(t0)	# blue
	or	a0, a0, a1	# change BGR format to RGB

	
	addi	t0, t0, 3	# go to next 3 bytes to read next pixel
	
	bltz	t4, skip_pixel	# if we are out of screen from the left - do not draw pixel
	li	a3, SCREEN_WIDTH
	bge	t4, a3, skip_pixel	# if we are out of screen from the right - do not draw the pixel
	
	bltz    t1, skip_pixel	# if the y < 0 - skip pixel
	li      a3, SCREEN_HEIGHT
	bge     t1, a3, skip_pixel	# if y >= screen height - skip pixel
	 
	slli	a2, t1, 9      	# a2 = y * 512
	add	a2, a2, t4      # a2 = (y * 512) + x
	slli	a2, a2, 2       # a2 = ((y * 512) + x) * 4 
	
	add	a2, a2, a7      # a2 = base display address + offset
	
	sw	a0, 0(a2)       # show pixel on the screen
	
skip_pixel:
	addi	t5, t5, -1
	addi	t4, t4, 1	# go to next pixel
	
	bnez	t5, inner_loop
	
	add	t6, t6, a6	# add to current pixel address stride to come to new row
	mv	t0, t6		# update pixel start
	
	add	t1, t1, t2	# update row - either incr or decr(depending on t2, which step based on height's sign)

	addi	t3, t3, -1	# update the outer loop counter which is height
	
	bnez	t3, outer_loop
	
epilogue:
	ret
	
clear_screen:
	li	t0, 0x10040000	# base heap address
	li	t1, 0		# black colour
	li	t2, SCREEN_WIDTH
	li	t3, SCREEN_HEIGHT	
	mul	t4, t2, t3	# pixels per screen
	
clear_loop:
	sw	t1, 0(t0)
	addi	t0, t0, 4	# cause 4 bytes per pixel
	addi	t4, t4, -1
	bnez	t4, clear_loop
	
	ret

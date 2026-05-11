	.eqv	WINDOW_WIDTH, 512
	.eqv	WIDTH_SHIFT, 9
main:
	li	t1, WINDOW_WIDTH
	slli	a0, t1, WIDTH_SHIFT	# size of window - 512 * 512
	slli	a0, a0, 2	# number of used bytes - each pixel is 4 bytes, so size of window * 4
	li	a7, 9		# allocate memroy on heap
	ecall			# after this in a0 we have the address of 1st pixel
	
	li	t0, 0x00FF00FF	# choose a colour to print
	mv	t1, a0		# the address of the first pixel
	
	li	t2, WINDOW_WIDTH
	slli	t2, t2, WIDTH_SHIFT	# the window size
	slli	t2, t2, 2	# the number of bytes
	add	t2, t2, t1	# the end address - begin address + window size
loop:
	sw	t0, 0(t1)	# store the colour
	addi	t1, t1, 4	# go to next pixel
	bltu	t1, t2, loop	# if we have not reached the end of vector - repeat the lopp
fin:
	li	a7, 10
	ecall
	
	
	
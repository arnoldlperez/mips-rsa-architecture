.data
A: .space 100
.text

la $t0, A #address to store results

li $s0, 0 #address index
li $s1, 100 #loop end condition MUST BE E - 1!!!!!!!!!!!!
li $s2, 0x12345678 #value to multiply exponentially
sw $s2, A #initially set the first register to 0x12345678

loop1:
beq $s1, $zero, exit #when its multiplied E times, exit the loop
addi $t4, $s0, 4 #for inner loop

	loop2:
	beq $t4, $zero, exit_loop2
	lw $t1, A+-4($t4) #load the last register of number to multiply by 0x12345678
	multu $t1, $s2 #multiply

	mflo $t2 #get lo and add it to the register it should go in
	lw $t3, A($t4)
	addu $t3, $t3, $t2
	sw $t3, A($t4)
	sltu $s5, $t2, $t3 #check carry bit

	mfhi $t2 #get hi
	#addu $t2, $t2, $s5
	sw $t2 A+-4($t4) #set next register to hi 
	
	addi $t4, $t4, -4 #repeat this until the number is finished (all registers are processed for multiplication)
	j loop2

exit_loop2: #next exponent
addiu $s0, $s0, 4
addi $s1, $s1, -1
j loop1

exit:
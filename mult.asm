.data
num1: .space 16
num2: .space 16
product: .space 1
.text

add $t0, $zero, 0x10bf17c0
sw $t0, num1
add $t0, $zero, 0xbc8eb230
sw $t0, num1+4
add $t0, $zero, 0x116f7ef6
sw $t0, num1+8
add $t0, $zero, 0x8e65642a
sw $t0, num1+12
add $t0, $zero, 0xebb92708
sw $t0, num2
add $t0, $zero, 0x21c153f8
sw $t0, num2+4
add $t0, $zero, 0x366e24c0
sw $t0, num2+8
add $t0, $zero, 0xd9ae1591
sw $t0, num2+12

la $a0, num1
la $a1, num2
la $a2, product
#----------


move $s0, $a0 #address of num1
move $s1, $a1 #address of num2
move $s2, $a2 #address of num3

add $t0, $zero, $zero #for value of num1
add $t1, $zero, $zero #for value of num2
add $t2, $zero, $zero #for value of product
add $t3, $zero, $zero #temp for lo/hi
add $t4, $zero, $zero #check for carry
add $t5, $zero, $zero #n index decrement
j multiply

next_num2:
addiu $s1, $s1, 4
addiu $t5, $t5, 4
addu $s2, $zero, $t5
lw $t1, ($s1)
beqz $t1, exit

multiply:
#load the next register of num2
lw $t1, ($s1)

#reset num1 variables
move $s0, $a0
move $t0, $zero

next_num1:
#load the next register of num2
lw $t0, ($s0)
beqz $t0, next_num2

#multiply the two numbers
multu $t0, $t1

#load current contents of product register and add HI to it
lw $t2, ($s2)
mfhi $t3
addu $t2, $t2, $t3
sw $t2, ($s2)

#add carry bit to next register to the left
sltu $t4, $t2, $t3
beqz $t4, no_carry_hi
lw $t2, -4($s2)
addu $t2, $t2, $t4
sw $t2, -4($s2)
no_carry_hi:

#go to next register of product
addiu $s2, $s2, 4

#load contents of product register and add LO to it
lw $t2, ($s2)
mflo $t3
addu $t2, $t2, $t3
sw $t2, ($s2)

#add carry bit to next register to the left
sltu $t4, $t2, $t3
beqz $t4, no_carry_lo
lw $t2, -4($s2)
addu $t2, $t2, $t4
sw $t2, -4($s2)
no_carry_lo:

addiu $s0, $s0, 4
j next_num1

exit:

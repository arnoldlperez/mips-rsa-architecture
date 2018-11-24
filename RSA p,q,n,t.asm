#Reads P and Q, then parses them from strings to integers. Computes N and T
.data
string_P: .space 128
string_Q: .space 128
P: .space 64
Q: .space 64
N: .space 128
Totient: .space 128
E: 0x10001
file: .asciiz "test.txt"
.text

#open file
li $v0, 13
la $a0, file
li $a1, 0
li $a2, 0
syscall
move $s6, $v0

#there are always 308 digits of P and Q.
#read the first prime P from first line
li $v0, 14
move $a0, $s6
la $a1, string_P
li $a2, 128
syscall

#skip the newline
li $v0, 14
la $a1, 0x100103c0
li $a2, 2
syscall
sw $zero, 0x100103c0

#read the second prime Q
li $v0, 14
la $a1, string_Q
li $a2, 128
syscall

#variables required for parsing process
add $t0, $zero, $zero
add $t4, $zero, $zero
add $t6, $zero, 28

parsing_P:
#load byte from unparsed address
lb $t2, string_P($t0)
bge $t2, 60, hex_letter_P

#convert to hex (if digit is 0-9)
addi $t2, $t2, -48
sllv $t2, $t2, $t6
j cont_P

#convert to hex (if digit is A-F)
hex_letter_P:
addi $t2, $t2, -55
sllv $t2, $t2, $t6

cont_P:
#load current contents of parsed address
lw $t3, P($t4)

#add new parsed digit and store back to address
add $t2, $t2, $t3
sw $t2, P($t4)

#update variables for next byte
addi $t0, $t0, 1
addi $t6, $t6, -4

#if all bytes are parsed, then parsing_P is completed
beq $t0, 128, done_parsing_P

#if current address has 8 bytes then go on to the next address
remu $t5, $t0, 8
beq $t5, $zero, nextaddress_P
j parsing_P

#update variable for next address of parsed_p
nextaddress_P:
add $t4, $t4, 4
j parsing_P

#parsing_P is completed; continue to Q
done_parsing_P:

#reset variables
move $t0, $zero
move $t2, $zero
move $t3, $zero
move $t4, $zero
move $t5, $zero
add $t6, $zero, 28

parsing_Q:
#load byte from unparsed address
lb $t2, string_Q($t0)
bge $t2, 60, hex_letter_Q

#convert to hex (if digit is 0-9)
addi $t2, $t2, -48
sllv $t2, $t2, $t6
j cont_Q

#convert to hex (if digit is A-F)
hex_letter_Q:
addi $t2, $t2, -55
sllv $t2, $t2, $t6

cont_Q:
#load current contents of parsed address
lw $t3, Q($t4)

#add new parsed digit and store back to address
add $t2, $t2, $t3
sw $t2, Q($t4)

#update variables for next byte
addi $t0, $t0, 1
addi $t6, $t6, -4

#if all bytes are parsed, then parsing_Q is completed
beq $t0, 128, done_parsing_Q

#if current address has 8 bytes then go on to the next address
remu $t5, $t0, 8
beq $t5, $zero, nextaddress_Q
j parsing_Q

#update variable for next address of parsed_Q
nextaddress_Q:
add $t4, $t4, 4
j parsing_Q

#parsing_Q is completed
done_parsing_Q:
#prepare to compute N

add $s0, $zero, 64 #index for P
add $t0, $zero, $zero #for value of p

add $s1, $zero, 64 #index for Q
add $t1, $zero, $zero #for value of q

add $s2, $zero, 128 #initial index for N
add $t2, $zero, $zero #for value of n
add $t6, $zero, $zero #n index decrement

add $t3, $zero, $zero #mult temp lo/hi
add $s5, $zero, $zero #check for carry

#time to compute N = P * Q
next_Q:
add $s1, $s1, -4
lw $t1, Q($s1)

add $s0, $zero, 64 #index for P
add $t0, $zero, $zero #for value of p

add $t6, $t6, -4
add $s2, $t6, 128

next_P:
add $s0, $s0, -4
lw $t0, P($s0)

multu $t0, $t1

lw $t2, N($s2)
mflo $t3
addu $t2, $t2, $t3
sw $t2, N($s2)

#check for carry bit
sltu $s5, $t2, $t3

#next location of N
add $s2, $s2, -4

lw $t2, N($s2)
mfhi $t3
addu $t2, $t2, $s5
addu $t2, $t2, $t3
sw $t2, N($s2)

sltu $s5, $t2, $t3

lw $t2, N+-4($s2)
addu $t2, $t2, $s5
sw $t2, N+-4($s2)

beq $s2, $zero, computed_N
beq $s0, $zero, next_Q
j next_P

computed_N:

#make P = P-1 and Q = Q-1 temporarily to compute Totient = p-1 * q-1
lw $t0, P+60
lw $t1, Q+60
addiu $t0, $t0, -1
addiu $t1, $t1, -1
sw $t0, P+60
sw $t1, Q+60

#compact code because its same as calculating N
add $s0, $zero, 64
add $t0, $zero, $zero
add $s1, $zero, 64
add $t1, $zero, $zero
add $s2, $zero, 128
add $t2, $zero, $zero
add $t6, $zero, $zero
add $t3, $zero, $zero
add $s5, $zero, $zero
Totient_next_Q:
add $s1, $s1, -4
lw $t1, Q($s1)
add $s0, $zero, 64 #index for P
add $t0, $zero, $zero #for value of p
add $t6, $t6, -4
add $s2, $t6, 128
Totient_next_P:
add $s0, $s0, -4
lw $t0, P($s0)
multu $t0, $t1
lw $t2, Totient($s2)
mflo $t3
addu $t2, $t2, $t3
sw $t2, Totient($s2)
sltu $s5, $t2, $t3
add $s2, $s2, -4
lw $t2, Totient($s2)
mfhi $t3
addu $t2, $t2, $s5
addu $t2, $t2, $t3
sw $t2, Totient($s2)
sltu $s5, $t2, $t3
lw $t2, Totient+-4($s2)
addu $t2, $t2, $s5
sw $t2, Totient+-4($s2)
beq $s2, $zero, computed_Totient
beq $s0, $zero, Totient_next_Q
j Totient_next_P

computed_Totient:

#revert P and Q to their original values by adding 1 to each
lw $t0, P+60
lw $t1, Q+60
addiu $t0, $t0, 1
addiu $t1, $t1, 1
sw $t0, P+60
sw $t1, Q+60

.data
P: .space 4
Q: .space 4
N: .space 4
T: .space 4
D: .space 4
E: .word 3
encrypted_register: .space 4
decrypted_register: .space 4

unparsed_MSG: .space 80
MSG: .space 80

parsed_encrypted_MSG: .space 80
encrypted_MSG: .space 80

PQ_file: .asciiz "PQ.txt"
MSG_file: .asciiz "message.txt"
encrypted_file: .asciiz "encrypted.txt"
decrypted_file: .asciiz "decrypted.txt"
prompt: .asciiz "Enter 0 for encrypttion, or 1 for decryption"
.text

#open file containing P and Q
li $v0, 13
la $a0, PQ_file
li $a1, 0
li $a2, 0
syscall
move $s0, $v0

#read P as a string
li $v0, 14
move $a0, $s0
la $a1, P
li $a2, 1
syscall

#skip the newline
li $v0, 14
la $a1, 0x100103c0
li $a2, 2
syscall
sw $zero, 0x100103c0

#read Q as a string
li $v0, 14
la $a1, Q
li $a2, 1
syscall

#need to convert the P we read into an integer
parsing_P:
#load byte from unparsed address
lb $t2, P($t0)
bge $t2, 60, hex_letter_P

#convert to hex (if digit is 0-9)
addi $t2, $t2, -48
j done_parsing_p

#convert to hex (if digit is A-F)
hex_letter_P:
addi $t2, $t2, -55

#store parsed P into register of P
done_parsing_p:
sw $t2, P($t4)

#now time to convert Q into an integer
parsing_Q:
#load byte from unparsed address
lb $t2, Q($t0)
bge $t2, 60, hex_letter_Q

#convert to hex (if digit is 0-9)
addi $t2, $t2, -48
j done_parsing_Q

#convert to hex (if digit is A-F)
hex_letter_Q:
addi $t2, $t2, -55

#store parsed Q into register of Q
done_parsing_Q:
sw $t2, Q($t4)

#compute N
lw $t0, P
lw $t1, Q
multu $t1, $t0
mflo $t0
sw $t0, N

#compute T
lw $t0, P
addi $t0, $t0, -1
lw $t1, Q
addi $t1, $t1, -1
multu $t0, $t1
mflo $t0
sw $t0, T

#compute D = (1 + K*T) / E for some int K
li $t0, 1 #K = 1
lw $t1, T
lw $t2, E
multu $t0, $t1
mflo $t0 	  #$t0 = K*T
addiu $t0, $t0, 1 #$t0 = 1 + K*T
divu $t0, $t2
mflo $t0	  #t0 = D = (1+ K*T) / E
sw $t0, D

############
# Menu
############

#print prompt asking for encryption/decryption
li $v0, 4
la $a0, prompt
syscall

#read input
li $v0, 5
syscall
move $t0, $v0

#jump to desired location
bnez $t0, decryption

encryption:
############
# ENCRYPTION
############

#open message file
li $v0, 13
la $a0, MSG_file
li $a1, 0
li $a1, 0
syscall
move $s0, $v0

#read message into buffer
li $v0, 14
move $a0, $s0
la $a1, unparsed_MSG
li $a2, 80
syscall

#now need to compress message
move $t1, $zero
parsing_msg_loop:
lb $t0, unparsed_MSG($t1)
beqz $t0, exit_parsing_msg_loop #exit when the next taken bit is 0
addi $t0, $t0, -0x60
sb $t0, MSG($t1)
addi $t1, $t1, 1
j parsing_msg_loop
exit_parsing_msg_loop:

#open file to write out to
li $v0, 13
la $a0, encrypted_file
li $a1, 1
li $a2, 0
syscall
move $s1, $v0

#start encrypting the message byte-by-byte
move $t1, $zero
lw $t3, N
encrypting_loop:
#exponentiate by E
lb $t0, MSG($t1)
beqz $t0, finished_encrypting

move $t2, $t0
move $t5, $zero
encrypting_exponentiation_loop:
multu $t2, $t0
mflo $t2
addiu $t5, $t5, 1
beq $t5, 4, done_exponentiating_encryption
j encrypting_exponentiation_loop
done_exponentiating_encryption:

#mod N
divu $t2, $t3
mfhi $t4

#restore back to "unparsed" version
addi $t4, $t4, 0x60
sw $t4, encrypted_register

#write encrypted byte to file
li $v0, 15
move $a0, $s1
la $a1, encrypted_register
li $a2, 1
syscall

addi $t1, $t1, 1
j encrypting_loop

finished_encrypting:

#close the file
li $v0, 16
move $a0, $s1
syscall

j exit_program

decryption:
############
# DECRYPTION
############

#open encrypted message file
li $v0, 13
la $a0, encrypted_file
li $a1, 0
li $a1, 0
syscall
move $s0, $v0

#read message into buffer
li $v0, 14
move $a0, $s0
la $a1, parsed_encrypted_MSG
li $a2, 80
syscall

#compressing the encrypted message
move $t1, $zero
parsing_encrypted_msg_loop:
lb $t0, parsed_encrypted_MSG($t1)
beqz $t0, exit_parsing_encrypted_msg_loop #exit when the next taken bit is 0
addi $t0, $t0, -0x60
sb $t0, encrypted_MSG($t1)
addi $t1, $t1, 1
j parsing_encrypted_msg_loop
exit_parsing_encrypted_msg_loop:


#open file to write out to
li $v0, 13
la $a0, decrypted_file
li $a1, 1
li $a2, 0
syscall
move $s1, $v0


#start decrypting the message byte-by-byte
move $t1, $zero
lw $t3, N
decrypting_loop:
#exponentiate by E
lb $t0, encrypted_MSG($t1)
beqz $t0, finished_decrypting

move $t2, $t0
move $t5, $zero
decrypting_exponentiation_loop:
multu $t2, $t0
mflo $t2
addiu $t5, $t5, 1
beq $t5, 4, done_exponentiating_decryption
j decrypting_exponentiation_loop
done_exponentiating_decryption:

#mod N
divu $t2, $t3
mfhi $t4

#restore back to "unparsed" version
addi $t4, $t4, 0x60
sw $t4, decrypted_register

#write encrypted byte to file
li $v0, 15
move $a0, $s1
la $a1, decrypted_register
li $a2, 1
syscall

addi $t1, $t1, 1
j decrypting_loop

finished_decrypting:
j exit_program


exit_program:
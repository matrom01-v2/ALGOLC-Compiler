.data # start of the DATA section

_L0:	.asciiz	"\n"
_L1:	.asciiz	"Enter a number for x: \n"
_L2:	.asciiz	"Countdown from x:\n"
_L3:	.asciiz	"The square is: "
_L4:	.asciiz	"\nShoving that into the array at z[x]\nz[x] is now: \n"
_L5:	.asciiz	"\n\ntesting expression inside arrays:\n"
_L6:	.asciiz	"z[ "
_L7:	.asciiz	"x + 4 + z[x]] is now:\n"
_L8:	.asciiz	"\n\nthe index was: "

_NL: .asciiz "\n" # New line

.align 2 # start all globa variables aligned

x:		 .space 4		 # define global variable
y:		 .space 4		 # define global variable
z:		 .space 400		 # define global variable
a:		 .space 4		 # define global variable
b:		 .space 4		 # define global variable
c:		 .space 4		 # define global variable

.text # start of code segment

.globl main

countDown:		# Start of function

		subu $t0 $sp 24		# new stack pointer
		sw $ra ($t0)	# store the return address
		sw $sp 4($t0)	# store the old sp
		move $sp $t0	# set sp

		li $a0 8
		add $a0, $a0, $sp
		lw $a0 ($a0)	# gets value into a0
		sw $a0, 12($sp)		# store LHS
		li $a0 0	# load a number expr
		move $a1, $a0	# move RHS to b0
		lw $a0, 12($sp)		# load a0 with result
		slt $t1, $a0, $a1	# EQ expr
		slt $t2, $a1, $a0	# EQ expr
		nor $a0, $t1, $t2	# EQ expr
		andi $a0, 1	# EQ expr final compare
		beq $a0 $0 _L9	#  jump to else
		li $v0 0	# return NULL
		lw $ra ($sp)	# reset ra
		lw $sp 4($sp)	# reset sp to old sp
		jr $ra	# go back to function call
		j _L10	#  IF s1 end

_L9:		# start of ELSE
		li $a0 8
		add $a0, $a0, $sp
		lw $a0 ($a0)	# gets value into a0
		li $v0 1	# command for write nums
		syscall

		li $v0, 4	# printing a string
		la $a0, _L0		# string location print
		syscall


_L10:		# END IF
		subu $t2 $sp 24	# carve out memory for activation record
		li $a0 8
		add $a0, $a0, $sp
		lw $a0 ($a0)	# gets value into a0
		sw $a0, 16($sp)		# store LHS
		li $a0 1	# load a number expr
		move $a1, $a0	# move RHS to b0
		lw $a0, 16($sp)		# load a0 with result
		sub $a0, $a0, $a1	# SUB expr

		sw $a0 8($t2)	# store in needed location
		jal countDown	# jump to fucntion


		li $v0 0	# return NULL
		lw $ra ($sp)	# reset ra
		lw $sp 4($sp)	# reset sp to old sp

		jr $ra	# go back to function call

square:		# Start of function

		subu $t0 $sp 16		# new stack pointer
		sw $ra ($t0)	# store the return address
		sw $sp 4($t0)	# store the old sp
		move $sp $t0	# set sp

		li $a0 8
		add $a0, $a0, $sp
		lw $a0 ($a0)	# gets value into a0
		sw $a0, 12($sp)		# store LHS
		li $a0 8
		add $a0, $a0, $sp
		lw $a0 ($a0)	# gets value into a0
		move $a1, $a0	# move RHS to b0
		lw $a0, 12($sp)		# load a0 with result
		mult $a0 $a1	# 	MULT expr
		mflo $a0	# 	MULT expr
		move $v0 $a0	# move a0 into v0
		lw $ra ($sp)	# reset ra
		lw $sp 4($sp)	# reset sp to old sp
		jr $ra	# go back to function call

		li $v0 0	# return NULL
		lw $ra ($sp)	# reset ra
		lw $sp 4($sp)	# reset sp to old sp

		jr $ra	# go back to function call

main:		# Start of function

		subu $t0 $sp 64		# new stack pointer
		sw $ra ($t0)	# store the return address
		sw $sp 4($t0)	# store the old sp
		move $sp $t0	# set sp

		li $v0, 4	# printing a string
		la $a0, _L1		# string location print
		syscall

		la $a0 x		# load global variable
		li $v0 5	# read num
		syscall
		sw $v0 ($a0)	#  end read statement

		li $v0, 4	# printing a string
		la $a0, _L2		# string location print
		syscall

		subu $t2 $sp 24	# carve out memory for activation record
		la $a0 x		# load global variable
		lw $a0 ($a0)	# gets value into a0
		sw $a0 8($t2)	# store in needed location
		jal countDown	# jump to fucntion

		li $v0, 4	# printing a string
		la $a0, _L3		# string location print
		syscall

		subu $t2 $sp 16	# carve out memory for activation record
		la $a0 x		# load global variable
		lw $a0 ($a0)	# gets value into a0
		sw $a0 8($t2)	# store in needed location
		jal square	# jump to fucntion

		li $v0 1	# command for write nums
		syscall

		subu $t2 $sp 16	# carve out memory for activation record
		la $a0 x		# load global variable
		lw $a0 ($a0)	# gets value into a0
		sw $a0 8($t2)	# store in needed location
		jal square	# jump to fucntion

		sw $a0 20($sp)	# store RHS
		la $a0 x		# load global variable
		lw $a0 ($a0)	# gets value into a0
		sll $t3, $a0, 2	# mult by wordsize
		la $a0 z		# load global variable
		add $a0, $a0, $t3	# add on for arrays
		lw $a1 20($sp)	# Get RHS
		sw $a1 ($a0)	# assign value

		li $v0, 4	# printing a string
		la $a0, _L4		# string location print
		syscall

		la $a0 x		# load global variable
		lw $a0 ($a0)	# gets value into a0
		sll $t3, $a0, 2	# mult by wordsize
		la $a0 z		# load global variable
		add $a0, $a0, $t3	# add on for arrays
		lw $a0 ($a0)	# gets value into a0
		li $v0 1	# command for write nums
		syscall

		li $v0, 4	# printing a string
		la $a0, _L5		# string location print
		syscall

		la $a0 x		# load global variable
		lw $a0 ($a0)	# gets value into a0
		sw $a0, 32($sp)		# store LHS
		li $a0 4	# load a number expr
		move $a1, $a0	# move RHS to b0
		lw $a0, 32($sp)		# load a0 with result
		add $a0, $a0, $a1	# ADD expr

		sw $a0, 40($sp)		# store LHS
		subu $t2 $sp 16	# carve out memory for activation record
		li $a0 3	# load a number expr
		sw $a0 8($t2)	# store in needed location
		jal square	# jump to fucntion

		move $a1, $a0	# move RHS to b0
		lw $a0, 40($sp)		# load a0 with result
		add $a0, $a0, $a1	# ADD expr

		sw $a0 44($sp)	# store RHS
		la $a0 x		# load global variable
		lw $a0 ($a0)	# gets value into a0
		sw $a0, 24($sp)		# store LHS
		li $a0 4	# load a number expr
		move $a1, $a0	# move RHS to b0
		lw $a0, 24($sp)		# load a0 with result
		add $a0, $a0, $a1	# ADD expr

		sw $a0, 28($sp)		# store LHS
		la $a0 x		# load global variable
		lw $a0 ($a0)	# gets value into a0
		sll $t3, $a0, 2	# mult by wordsize
		la $a0 z		# load global variable
		add $a0, $a0, $t3	# add on for arrays
		lw $a0 ($a0)	# gets value into a0
		move $a1, $a0	# move RHS to b0
		lw $a0, 28($sp)		# load a0 with result
		add $a0, $a0, $a1	# ADD expr

		sll $t3, $a0, 2	# mult by wordsize
		la $a0 z		# load global variable
		add $a0, $a0, $t3	# add on for arrays
		lw $a1 44($sp)	# Get RHS
		sw $a1 ($a0)	# assign value

		li $v0, 4	# printing a string
		la $a0, _L6		# string location print
		syscall

		li $v0, 4	# printing a string
		la $a0, _L7		# string location print
		syscall

		la $a0 x		# load global variable
		lw $a0 ($a0)	# gets value into a0
		sw $a0, 48($sp)		# store LHS
		li $a0 4	# load a number expr
		move $a1, $a0	# move RHS to b0
		lw $a0, 48($sp)		# load a0 with result
		add $a0, $a0, $a1	# ADD expr

		sw $a0, 52($sp)		# store LHS
		la $a0 x		# load global variable
		lw $a0 ($a0)	# gets value into a0
		sll $t3, $a0, 2	# mult by wordsize
		la $a0 z		# load global variable
		add $a0, $a0, $t3	# add on for arrays
		lw $a0 ($a0)	# gets value into a0
		move $a1, $a0	# move RHS to b0
		lw $a0, 52($sp)		# load a0 with result
		add $a0, $a0, $a1	# ADD expr

		sll $t3, $a0, 2	# mult by wordsize
		la $a0 z		# load global variable
		add $a0, $a0, $t3	# add on for arrays
		lw $a0 ($a0)	# gets value into a0
		li $v0 1	# command for write nums
		syscall

		li $v0, 4	# printing a string
		la $a0, _L8		# string location print
		syscall

		la $a0 x		# load global variable
		lw $a0 ($a0)	# gets value into a0
		sw $a0, 56($sp)		# store LHS
		li $a0 4	# load a number expr
		move $a1, $a0	# move RHS to b0
		lw $a0, 56($sp)		# load a0 with result
		add $a0, $a0, $a1	# ADD expr

		sw $a0, 60($sp)		# store LHS
		la $a0 x		# load global variable
		lw $a0 ($a0)	# gets value into a0
		sll $t3, $a0, 2	# mult by wordsize
		la $a0 z		# load global variable
		add $a0, $a0, $t3	# add on for arrays
		lw $a0 ($a0)	# gets value into a0
		move $a1, $a0	# move RHS to b0
		lw $a0, 60($sp)		# load a0 with result
		add $a0, $a0, $a1	# ADD expr

		li $v0 1	# command for write nums
		syscall


		li $v0 0	# return NULL
		lw $ra ($sp)	# reset ra
		lw $sp 4($sp)	# reset sp to old sp

		li $v0 10
		syscall	# RETURN OUT MIPS

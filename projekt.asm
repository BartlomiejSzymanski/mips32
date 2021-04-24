# Program zamieniajacy date z dowolnej formy do ujednoliconej
# Autor: Bartlomiej Szymanski  Proba tekstu 123 12.10 12.10.2020

	.data

msg1:	.asciiz "Provide file name for date conversion \n"
msg2:	.asciiz "For format DD.MM.YYY 	 enter 1 \n"
msg3:	.asciiz "For format MM/DD/YY  	 enter 2 \n"
msg4:	.asciiz "For format YYYY-MM--DD   enter 3 \n"
msg5:	.asciiz "Wrong input, try again \n"
msg6:	.asciiz "No such file \n"
msg7:	.asciiz "Empty file, please provide file with data"


name_buf:.space 32			#filename for input		
line_buf:.space 50
word_buf:.space 10			#date length


# registers:
#   t0 -- pointer to source
#   t1 -- 
#   t2 -- 
#   t3 -- 
#   t4 -- 
#   t5 -- counter
#   t6 -- date format flag
#   t7 -- file descriptor

	
	.text
	
main:	

	li	$v0, 4
	la	$a0, msg1			#Print "Provide file name for date conversion
	syscall
	
	li 	$v0, 8
	la	$a0, name_buf			#Read string to namebuf
	la 	$a1, 32				#max str length	
	syscall
	la 	$t0, name_buf			#source
		
clean_LF:
	
	
	lbu	$t1, ($t0)			#load char to $t1
	addiu	$t0, $t0, 1			#increment ptr to next char in $t0
	bne	$t1, '\n', clean_LF		#while not equal to '\n' 
	subiu	$t0, $t0, 1
	li	$t2, 0			
	sb	$t2, ($t0)			#if equal store 0 to adress
	lbu	$t1, ($t0)

open_file:

	li 	$v0, 13				#instruction for opening file
	la	$a0, name_buf			#name from namebuf
	li	$a1, 0				#flag for reading
	li 	$a2, 0				#mode is ignored
	syscall
	bne	$v0, -1, read_file

file_rror:
	li 	$v0, 4
	la	$a0, msg6			#Print "No such file"
	syscall
	j	main	
	
	
read_file:
	# read from file
	move 	$t7, $v0			#save descriptor to new reg
	li 	$v0, 14				#read from file
	la	$a0, ($t7)			#file descriptor
	la	$a1, line_buf			#address of a buffer
	li	$a2, 50				# max str length
	syscall
	
	bne	$v0, 0, date_format

error_empty_file:
	
	li 	$v0, 4	
	la	$a0, msg7			#if file empty print message
	syscall	
	j	main
	
error_wrong_input:
	li	$v0, 4
	la	$a0, msg5			#Print "Wrong input, try again"
	syscall
	
	
date_format:	
	li 	$v0, 4
	la	$a0, msg2			#Print "For format DD.MM.YY enter 1"
	syscall
	li 	$v0, 4
	la	$a0, msg3			#Print "For format MM/DD/YY  enter 2"
	syscall
	li 	$v0, 4
	la	$a0, msg4			#Print "For format YYYY-MM-DD enter 3"
	syscall
	li 	$v0, 5				#Load date format from user input
	syscall
	

check_date_format:
	
	move 	$t6, $v0			#copy user input to reg
	blt	$t6, 1, error_wrong_input	#if wrong input, write message	
	bgt	$t6, 3, error_wrong_input
	
	
# ============================================================================  	
# find_word
# description: 
#	iterates through buffer and adds char from current ptr to wordbuffer
# arguments: none
# variables:
#	$s0 - ptr to line_buffer
#	$s1 - current char 
#	$s2 - ptr to wordbuff
#	$s3 - ptr to wordbuff copy
#	$s4 - 
# returns: none	
isolate_word:
	subiu	$sp, $sp, 20
	sw	$ra, 16($sp)			# push $ra
	sw	$s0, 12($sp)			# push $s0
	sw	$s1, 8($sp)			# push $s1
	sw	$s2, 4($sp)			# push $s2
	sw	$s3, 0($sp)			# push $s3

	la 	$s0, line_buf
	lw	$s0, ($s0)			#ptr to source linebuf
	la 	$s2, word_buf			# source ptr
	move	$s3, $s2			#ptr copy		
loop:	
	lbu	$s1, 0($s0)			#load letter from buf 
	addiu 	$s0, $s0, 1			#increment dest pointer
	beq	$s1, ' ', check_if_date		#if space then check if a word
	sb	$s1, ($s2)			#save byte to word buff 
	addiu 	$s2, $s2, 1
	j loop
		
check_if_date:
	lbu	$s1, ($s3)			#load char from wordbuf
	addiu 	$s3, $s3, 1
	blt	$s1, '0', clearbuf		#check if number
	bgt	$s1, '9', clearbuf
	addiu 	$s5, $s5, 1		
	blt	$s5, 2, loop		#while counter not equal 2 jump
	beq	$s1, '.' DDFormat
	beq	$s1, '/',MMFormat
check_YY..Format:

	lbu	$s1, ($s3)			#load char from wordbuf
	addiu 	$s3, $s3, 1	
	beq 	$s1, '/', YYFormat		# If YY/... then jump to YYformat	
	blt	$s1, '0', clearbuf		#if not a number, clear buffer
	bgt	$s1, '9', clearbuf	
	lbu	$s1, ($s3)			#load char from wordbuf
	addiu 	$s3, $t3, 1
	blt	$s1, '0', clearbuf		#if not a number, clear buffer
	bgt	$s1, '9', clearbuf
	lbu	$s1, ($s3)			#load char from wordbuf
	addiu 	$s3, $s3, 1
	bne	$s1, '-', clearbuf
	sb	$s5, 0				#reset counters
YYYYFormat:
	lbu	$s1, ($s3)			#load char from wordbuf
	addiu 	$s3, $s3, 1
	blt	$s1, '0', clearbuf		#if not a number, clear buffer
	bgt	$s1, '9', clearbuf
	addiu 	$s5, $s5, 1
	blt	$s5, 2, YYYYFormat		#while not YYYY-MM... jump
	
	lbu	$s1, ($s3)			#load char from wordbuf
	addiu 	$s3, $s3, 1
	bne	$s1, '-', clearbuf		#if not YYYY-MM- then clear buffer
	lbu	$s5, 0
last_digits:	
	lbu	$t1, ($t3)			#load char from wordbuf
	addiu 	$t3, $t3, 1
	blt	$t1, '0', clearbuf		#if not a number, clear buffer
	bgt	$t1, '9', clearbuf
	addiu 	$t5, $t5, 1
	blt	$t5, 2, last_digits
	j	format_date

YYFormat:
DDFormat:
MMFormat:
format_date:


clearbuf:

	
	
	
	
	

finish:
	
	li	$v0, 16		
	la	$a0, ($t0)
	syscall
	
	
	

	

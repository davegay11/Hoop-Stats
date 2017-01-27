# @author Dave Gay
# @since February 2016

.text
.align 2


main:
    li $v0, 4               #Print "Enter Player's last name: "
    la $a0, askForName
    syscall

    li $a0, 68          #Allocate 60 bytes of memory. 60 for name, 4 for ppm, 4 for pointer to next player
    li $v0, 9
    syscall
    move $s0, $v0         #pointer to memory in $s0

    la $a0, 0($s0)       #move pointer to memory to $a0
    li $a1, 60          #set memory for read in name to 60 bytes
    li $v0, 8
    syscall		       #player name is now in $a0


    la $a0, 0($s0)      # name in $a0
    la $a1, done        # "DONE\n" in $a1. The assignment states that this will be the last input
    jal checkDone


    li $t6, 1               # set $t6 to 1 to compare to the return value of checkDone
    li.s $f6, 100000005.0   # set the max value to be very high
    add $s3, $s1, $zero     # $s3 is also beginning of the list
    beq $v0, $t6, sort      # Check to see if checkDone returned 1 (true)


###############################################
# Name is not DONE. Continue reading in stats #
###############################################


    li $v0, 4           #Prints "Enter player's points per game: "
    la $a0, askForPPG
    syscall

    li $v0, 6
    syscall
    mov.s $f1, $f0     #PPG is in $f1




    li $v0, 4           #Prints "Enter player's minutes per game: "
    la $a0, askForMPG
    syscall

    li $v0, 6
    syscall
    mov.s $f2, $f0       # MPG is in $f2


    li.s $f4, 0.0       #set $f4 to 0.0 to compare PPG and MPG to.

    c.eq.s $f1, $f4     #check if PPG is 0
    bc1t setZero        #setZero makes points per minute 0.
    c.eq.s $f2, $f4     #check if mpg is 0
    bc1t setZero        #setZero makes points per minute 0.



    div.s $f3, $f1, $f2   #PPM IS IN $f3. We only get here if neither mpg or ppg is 0. Otherwise, $f3 is already 0


storePlayer:

    move $s1, $s0       #stores the player in memory
    swc1 $f3, 60($s1)
    sw $s2, 64($s1)
    move $s2, $s1

    j main              #read next input


checkDone:                      #Checks to see if the inputed name is "DONE"
    add $t0, $a0, $zero         #t0 is name
    add $t1, $a1, $zero         #t1 is "DONE\n"


compareBytes:
    lb $t2, ($t0)           #loads byte from name
    lb $t3, ($t1)           #loads byte from done
    beq $t2, $zero, endOfName      #if name has no more letters, branch
    beq $t3, $zero, return        #if done has no more letters, name is longer than done, so they are not equal. Continue reading inputs

    seq $t4, $t2, $t3       #set $t4 to 1 if $t2 and $t3 are equal, 0 otherwise

    beq $t4, $zero, return  #characters are not equal. Return to reading inputs
    addi $t0, $t0, 1        #move to the next byte of name
    addi $t1, $t1, 1        #move to the next byte of done
    j compareBytes


endOfName:                       #enter this when name is done
    bne $t3, $zero, return      #if done is not finished, name was shorter than done, so return to reading inputs


isDone:       #Only gets here if name is DONE
    li $v0, 1  #set $v0 to 1 (TRUE)
    j return


terminate:
    li $v0, 10             #terminate the program
    syscall



trim_newline:
# (no calls and no change to callee-saved regs, so no stack frame stuff needed here)
    li $t0,10			# t0 gets the newline character 0xa ('\n')
$L_loop:
    lb $t1, 0($a0)      # load this char
    beq	$t1,$t0,$L_end_loop # compare to newline, break if equal

    addiu $a0,$a0,1   # pointer++
    j $L_loop           # loop
$L_end_loop:
    sb $0, 0($a0)       # turn newline into a null terminator
    jr	$ra             # return



setZero:               #At least one of ppg or mpg is 0
    li.s $f3, 0.0      #Set points per minute to 0
    j storePlayer


return:
    jr $ra      #return




            #########################################################
            # All players have been inputed. Sort and print players #
            #########################################################




sort:       #$s1 and $s3 point to first name
            #60($s1) points to first ppm
            #64($s1) points to bext player

    #Find the min
    beq $s1, 0, resetList   # If we've read the whole list, we have the min, so print it.
    lwc1 $f5, 60($s1)           # $f5 is the current player's ppm

    c.le.s $f5, $f6             # If current player's ppm ($f5) is less than the min ($f6), set min to current's ppm
    bc1t updateMin


incrementHeap:                  # Go to next player in memory
    lw $t6, 64($s1)
    move $s1, $t6
    j sort


updateMin:              #update min
    mov.s $f6, $f5      #min is in $f6, current in $f5
    j incrementHeap


resetList:
    move $s1, $s3       # set $s1 to the head of the linked list


printMinCheck:
    li.s $f7, 100000000.0      #if min is 100000000.0, we've finished to sorting the list. end the program
    c.eq.s $f6, $f7
    bc1t terminate

    lwc1 $f8, 60($s1)   #Checks if current's ppm is min
    c.eq.s $f6, $f8
    bc1t print          #if so, print that player and set its ppm to 100000000

    lw $t8, 64($s1)     #increment to the next player in memory
    move $s1, $t8
    j printMinCheck


print:
    la $s6, 0($s1)         #Copy player's name into $s6
    add $a0, $zero, $s6    #Move player name into $a0 to pass into the trim function


    addi $sp, $sp, -8   #allocate space on the stack
    sw $t0, 0($sp)      #stores temp values on stack so if they get messed with in subroutine, it doesn't mess up what you're currently doing
    sw $t1, 4($sp)      #Caller saved registers

    jal trim_newline    #Trim the newline from name.

    lw $t0, 0($sp)      #restores $t0 and $t1 after the trimming function
    lw $t1, 4($sp)
    addi $sp, $sp, 8

    move $a0, $s6       #move name back into $a0
    li $v0, 4           #print name
    syscall

    la $a0, whitespace           #print whitespace
    syscall

    mov.s $f12, $f6     #print ppm
    li $v0, 2
    syscall


    li.s $f7, 100000000.0        #set ppm to 1000000000.0 in memory
    swc1 $f7, 60($s6)


    la $a0, newline         #print newline
    li $v0, 4
    syscall

    li.s $f6, 100000005.0
    move $s1, $s3
    j sort



.data

askForName: .asciiz "Enter player's last name: "

askForPPG: .asciiz "Enter player's points per game: "

askForMPG: .asciiz "Enter player's minutes per game: "

done: .asciiz "DONE\n"

newline: .asciiz "\n"

whitespace: .asciiz " "

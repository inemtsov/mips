# the game simply chooses a random secret number between 1 (min) and 0x64 (max)
# and request guesses from the user, telling them whether their guess is too high
# or too low until the number is found or user requests to quit. also it asks the 
# user if he or she wants to play again or quit.
#
#
    .data
prompt1: .asciiz "guess must be a hexadecimal number between 1 and 0x"
prompt2: .asciiz "\nEnter your guess (q to quit):"
prompt3: .asciiz "Guess is too low"
prompt4: .asciiz "Guess is too high"
prompt5: .asciiz "Got it!"
prompt6: .asciiz "Invalid Number!"
prompt7: .asciiz "Do you want to play again (q to quit)?"
    .align 2
min:     .word 1
max:     .word 0x64
offset:  .word 8226	
    .text
    .globl main
main:
# -- four arg regs
# -- 12 byte for character buffer ( at 16($sp) )
# -- two s-register 
# -- $ra 
    addiu   $sp,$sp -40,  
    sw  $ra,36($sp)
#   s0 - question    
    sw $s0, 32($sp) 
#   s1 - randomInt    
    sw $s1, 28($sp) 
    
#   itoax (max, buffer)
    lw $a0, max
    la $a1, 16($sp)
    jal itoax
    
#   question = create_question ( prompt1, buffer, prompt2 )
    la $a0, prompt1
    la $a1, 16($sp)
    la $a2, prompt2
    jal create_question
#   store the resul of create_question is s0 - question
    move $s0, $v0
    
#   initRandom(offset)
    lw $a0, offset
    jal InitRandom
    
Game: 
#   game starts here:     
#   randomInt = RandomIntRange ( min, max )
    lw $a0, min
    lw $a1, max
    jal RandomIntRange    
#    store the result of RandomIntRange in s1 - randomInt
    move $s1, $v0
 
Lguess:   
#   get_guess(question, min, max)
    move $a0, $s0
    lw $a1, min
    lw $a2, max
    jal get_guess
    
#   branch if guess is less than 0
    bltz $v0, quit
       
#   if ( guess == random ) { goto Lcorrect }
    beq $v0, $s1, Lcorrect
    
#   if ( guess > random { goto Lhigh }
    bgt $v0, $s1, Lhigh
    
#   if ( guess<random { goto Llow }
    blt $v0, $s1, Llow
        
Lhigh:
#   MessageDialog ( prompt4, type )
    la $a0, prompt4
    li $a1, 1
    jal MessageDialog
    b Lguess
   
Llow:
#   MessageDialog ( prompt3, type )
    la $a0, prompt3
    li $a1, 1
    jal MessageDialog
    b Lguess

Lcorrect:
#   MessageDialog ( prompt5, type )
    la $a0, prompt5
    li $a1, 1
    jal MessageDialog
   
#   InputDialogString ( prompt7, buffer, 12 )
    la $a0, prompt7
    la $a1, 16($sp)
    li $a2, 12
    jal InputDialogString
   
    bgez $v0, Game
     
quit:
#   end of the program
    lw $ra, 36($sp)
    lw $s0, 32($sp)
    lw $s1, 28($sp)
    addiu $sp,$sp,40
    jr  $ra
    
# int get_guess ( char *question, int min, int max ) {
# a finction to get a legal quess. it ensures the guess is in the legal range, then
# returns it.
    .globl get_guess
get_guess:
# -- four arg regs
# -- 12 byte for character buffer ( at 16($sp) )
# -- 1 word for *num
# -- $ra 
    addiu $sp,$sp,-36 
    sw  $ra, 32($sp)
#   buffer starts at 16($sp)
#   *num stored at 28($sp)
    sw $a0, 36($sp)
    sw $a1, 40($sp)
    sw $a2, 44($sp)
     
Linput:
#   InputDialogString ( question, buffer, 12 )
    lw $a0, 36($sp)
    la $a1, 16($sp)
    li $a2, 12
    jal InputDialogString
 
#   branch if guess is less than 0
    bltz $v0, return
     
#   axtoi ( num, buffer )
    la $a0, 28($sp)
    la $a1, 16($sp)
    jal axtoi
#   branch if guess is invalid     
    beqz $v0, invalid
     
#   if ( guess > max ) || ( guess < min ) goto invalid
    lw $v0, 28($sp)
    lw $a1, 40($sp)
    lw $a2, 44($sp)
     
    bgt $v0, $a2, invalid
    blt $v0, $a1, invalid
    b return
     
invalid:     
#   MessageDialog ( prompt6, type )
    la $a0, prompt6
    li $a1, 0
    jal MessageDialog
    b Linput
 
return:        
    lw $ra, 32($sp)
    addiu $sp, $sp, 36      
    jr  $ra
#}
   
# RandomIntRange.s
# a pair of function to deal with random numbers: InitRandom() and RandomIntRange()
# once a random number generator has been by a call to InitRandom, calling RandomIntRange 
# with a min and max values returns a random number in that range inclusive.

# int RandomIntRange ( int low, int high) {
# by calling RandomIntRange you get a secret number in the range [min max]
.text
    .globl RandomIntRange
RandomIntRange:
    addiu  $sp,$sp,-20
    sw  $ra,16($sp)
    sw  $a0, 20($sp)
    sw  $a1, 24($sp)
#   int random(void)
    jal random
    lw $a1, 24($sp)
    lw $a0, 20($sp)
#   (random % (high - low +1)) + low
    sub $t0, $a1, $a0
    addi $t0, $t0, 1
    divu $v0, $t0
    mfhi $v0
    add $v0, $v0, $a0
#   return
    lw  $ra,16($sp)
    addiu  $sp,$sp,20
    jr  $ra
#}
   
#  void InitRandom (int offset) {
#  InitRandom initializes the random number generator by getting the time of day
#  adding  4 - digit number - last 4 digits of my student ID and pass it as offset.
#  passing the resulting seed to srandom()
    .globl InitRandom
InitRandom:
    addiu  $sp,$sp,-20
    sw  $ra,16($sp)
    sw $a0, 20($sp)
#   time(0)
    move $a0, $zero
    jal time
#   adding offset to to the time
    lw $a0, 20($sp)
    add $a0, $a0, $v0
#   srandom(unsigned int seed)
    jal srandom
   
    lw  $ra,16($sp)
    addiu  $sp,$sp,20
    jr  $ra
#}
# create_question.s
# implements a function to assemble a question string from three parts
#
#   char * create_question(char * first, char * second, char * third);
#
# allocates space for a new string on the heap large enough to hold the 
# question, then fills the space by copying first, second and third, creating
# the concatenated question.
#
#  char * create_question( char * first, char * second, char * third) {
    .text
    .globl create_question
create_question:
    addiu  $sp,$sp,-40
    sw  $a0,40($sp)
    sw  $a1,44($sp)
    sw  $a2,48($sp)
    sw  $ra,36($sp)
#  int len1, len2, len3, len ;
#  char * question;
    # question - s0
    # len1 - s1
    # len2 - s2
    # len3 - s3
    # len - s4
    sw  $s4,32($sp)
    sw  $s3,28($sp)
    sw  $s2,24($sp)
    sw  $s1,20($sp)
    sw  $s0,16($sp)
#
#   len1 = strlen(first);
    jal strlen
    move $s1, $v0   
#   len2 = strlen(second);
    lw $a0 44($sp) 
    jal strlen
    move $s2, $v0
#   len3 = strlen(third);
    lw $a0, 48($sp)
    jal strlen
    move $s3, $v0	
#   len = len1 + len2 + len3;
    add $s4, $s1, $s2
    add $s4, $s4, $s3   
#   question = sbrk (len + 1);
    addi $s4, $s4, 1
    move $a0, $s4
    jal sbrk
    move $s0, $v0
#   strcpy(question,first);
    move $a0, $s0
    lw $a1, 40($sp) 
    jal strcpy
#   strcpy(question+len1, second);
    add $a0, $s0, $s1
    lw $a1, 44($sp)
    jal strcpy 
#   strcpy(question+len1+len2,third);
    add $a0, $s0, $s1
    add $a0, $a0, $s2
    lw $a1,  48($sp)
    jal strcpy
#   return(question);
    move $v0,$s0
    lw  $s4,32($sp)
    lw  $s3,28($sp)
    lw  $s2,24($sp)
    lw  $s1,20($sp)
    lw  $s0,16($sp)
    lw  $ra,36($sp)
    addiu  $sp,$sp,40
    jr  $ra
#}

#
# the following functions are used to implement syscalls from 
# MARS - This version simply call the appropriate syscalls with some
# massaging of the results. 
#
#  int InputDialogString (char *message, char * buf, int max) 
#     message is a message to be displayed
#     buf is a pointer to a character buffer at least of length max. 
#
#   The return value is the number of characters stored in buf, 
#   not counting the null byte (thus equivalent to strlen(buf)). 
#   If the user chose cancel in the dialog box, or types the 
#   single character q followed by a newline, the return value will be negative.
#
#   buf is always null-terminated and the newline does not appear in buf.  
#   If the user entered too much data, the extra data is lost.
#
	.text
    .globl  InputDialogString
InputDialogString:
    # int InputDialogString (char *message, char * buf, int max), 
    # leaf function
    # home arguments
    sw  $a0,0($sp)
    sw  $a1,4($sp)
    sw  $a2,8($sp)
    li  $t0,0
    sb  $t0,0($a1)
    li  $v0,54
    syscall
    li  $v0,-1
    beq $a1,-2,.IDSRet
    li  $v0,0
    beq $a1,-3,.IDSRet
    beq $a1,-4,.IDSstrlen
# 
#   check for q\n
#
    lw  $a1,4($sp)
    lb  $t0,0($a1)
    bne $t0,'q',.IDScont
    lb  $t0,1($a1)
    bne $t0,'\n',.IDScont
    li  $v0,-1
    b   .IDSRet
#
.IDScont:
    #
    # look for newline in buffer and store a nul byte on it
    #
    lw  $t0,4($sp)
.IDSck4null:
    lb  $t1,0($t0)
    beq $t1,$zero,.IDSstrlen
    bne $t1,'\n',.IDSnextbyte
    li  $t1,0
    sb  $t1,0($t0)
    b   .IDSstrlen
.IDSnextbyte:
    addi $t0,$t0,1
    b   .IDSck4null
.IDSstrlen:
    lw  $t0,4($sp)
    li $v0,0
.IDSstrlennext: 
    lb  $t1,0($t0)
    beq $t1,$zero,.IDSRet
    addi $t0,$t0,1
    addi $v0,$v0,1
    b   .IDSstrlennext
.IDSRet:
    jr  $ra
#
# void MessageDialog(char *message, int type).
#   the string message is output.
#   type is the same as that of syscall 55.
#
    .text
    .globl  MessageDialog
MessageDialog:
    # leaf. just do the syscall
    # arguments should be set correctly.
    li  $v0,55
    syscall
    jr  $ra
#
# void MessageDialogInt(char *message, int value)
#   the string message is output followed by the
#   integer value (translated to characters).
#
    .globl  MessageDialogInt
    # leaf. just a syscall
    # arguments are set correctly
MessageDialogInt:
    li  $v0,56
    syscall
    jr  $ra
#
# void PrintString(char *message)
#   prints the message using the old-fashioned SPIM syscalls
#
    .globl  PrintString
PrintString:
    li  $v0,4
    syscall
    jr  $ra
#
# void PrintInteger(int num)
#   prints the integer num using the old-fashioned SPIM syscalls
#
    .globl  PrintInteger
PrintInteger:
    li  $v0,1
    syscall
    jr  $ra
#
# void *sbrk(unsigned int nbytes)
#   returns a pointer to nbytes bytes of new memory
#   uses syscall 9
#
    .globl  sbrk
sbrk:
    li  $v0,9
    syscall
    # amazingly returns the pointer in $v0!
    jr  $ra
#
# void MessageDialogString(char *message, char *str)
#    uses syscall 59 to output a message followed by a string
#
    .globl  MessageDialogString
MessageDialogString:
    li  $v0,59
    syscall
    jr  $ra
#
# int InputDialogInt(char *message, int *num);
#   simple wrapper for syscall 51
#   any error from the syscall (negative status) is an error for IDI
#   errors are reported as a zero return value. 
#   A return value of 1 indicates success.
    .globl InputDialogInt
InputDialogInt:
    li  $v0,51
    # syscalls do not alter $v1, so use it to save num
    move    $v1,$a1
    syscall
    # this syscall has result in $a0, status in $a1
    # if error, just return
    move $v0,$zero
    bne $a1,$zero,.LIDIret
    li  $v0,1
    # store syscall return value into num
    sw  $a0,0($v1)
.LIDIret:
    jr  $ra
#
# int time(void)
#   uses syscall 30 to retrieve the time, discarding the high-order bits.
#   the low-order bits are converted to seconds and returned
#   NOTE: uses a divide instruction, so HI and LO are destroyed.
#
    .globl time
time:
    li      $v0,30
    syscall
    li      $v0,1000
    divu    $a0,$v0
    mflo    $v0
    jr      $ra
#
# void sleep(int nsecs)
#   uses syscall 32 to implement a sleep delay of nsecs seconds
#   NOTE: uses mult instruction, so LO and HI are destroyed.
#
    .globl sleep
sleep:
    # nsecs is in secs, syscall 32 wants milliseconds
    li      $v0,1000
    mult    $a0,$v0
    mflo    $a0
    li      $v0,32
    syscall
    jr      $ra
#
# void srandom(int seed)
#   sets the seed of random number generator #1
#   
    .globl srandom
srandom:
    move    $a1,$a0
    li      $a0,1
    li      $v0,40
    syscall
    jr      $ra
#
# unsigned int random(void)
#   using syscall 41, returns a pseudo-random integer in the range
#   [ 0, MAX ] using random number generator #1
#   MAX is implementation-defined.
#
    .globl  random
random:
    li      $a0,1
    li      $v0,41
    syscall
    move    $v0,$a0
    jr      $ra
#  
#
# axtoi.s - convert a string that 'looks like' a hex number
#       into the correponding integer.
#
#   int axtoi(int *num, char *string)
#
    .text
    .globl  axtoi
axtoi:
    # leaf procedure. no stack frame needed
    # $t0 is ch; $t1 is thisnum; $a0 is &num; $a1 is &string
    beq     $a1,$zero,.Laxtoifail
    beq     $a0,$zero,.Laxtoifail    # fail if either pointer arg is NULL
    sw      $zero,0($a0)        # initialize num to zero
.Laxtoiskip:
    lb      $t0,0($a1)          # ch = *string
    bne     $t0,$zero,.Laxtoiskipend # if (ch != 0) goto Laxtoiskipend
    add     $a1,$a1,1           # string++
    b       .Laxtoiskip
.Laxtoiskipend:
    beq     $t0,$zero,.Laxtoisucceed    # if (ch == 0) goto Laxtoisucceed
.Laxtoiloop:
    blt     $t0,'0',.Laxtoitrylower  # if ch is in ['0','9'], process it
    bgt     $t0,'9',.Laxtoitrylower
    sub     $t1,$t0,'0'
    b       .Laxtoiadd
.Laxtoitrylower:
    blt     $t0,'a',.Laxtoitryupper  # if ch is in ['a','f'], process it
    bgt     $t0,'f',.Laxtoitrynl
    sub     $t1,$t0,'a'
    add     $t1,$t1,10
    b       .Laxtoiadd
.Laxtoitryupper:
    blt     $t0,'A',.Laxtoitrynl      # if ch is in ['A','F'], process it
    bgt     $t0,'F',.Laxtoitrynl
    sub     $t1,$t0,'A'
    add     $t1,$t1,10
    b       .Laxtoiadd
.Laxtoitrynl:   
    bne     $t0,'\n',.Laxtoifail
    b       .Laxtoisucceed
.Laxtoiadd:  
    lw      $t2,0($a0)
    sll     $t2,$t2,4
    add     $t2,$t2,$t1
    sw      $t2,0($a0)
    add     $a1,$a1,1
    lb      $t0,0($a1)
    bne     $t0,$zero,.Laxtoiloop
.Laxtoisucceed:
    li      $v0,1
    jr      $ra
.Laxtoifail:
    li      $v0,0
    jr      $ra
# 
# unsigned strlen(const char *s) 
#  returns the length of s, not including the null byte
#  s is assumed to NOT be NULL
#
    .globl  strlen
strlen:
    # a0 has address of string
    li  $v0,-1
.Lstrlennext:
    lb  $t0,0($a0)
    addi $v0,$v0,1
    beq $t0,$zero,.Lstrlendone
    addi $a0,$a0,1
    b   .Lstrlennext
.Lstrlendone:
    jr  $ra
    .globl strcpy
strcpy:
# implements
#  char *strcpy(char *dest, char *src)
#  returning a pointer to dest.
#  dest is assumed to have room to store a copy of src.
#
    move    $v0,$a0
.Lstrcpynext:
    lb  $t0,0($a1)
    sb  $t0,0($a0)
    beq $t0,$zero,.Lstrcpydone
    addi    $a0,$a0,1
    addi    $a1,$a1,1
    b   .Lstrcpynext
.Lstrcpydone:
    jr  $ra
    .globl strncpy
strncpy:
# implements
#  char *strncpy(char *dest, char *src, int nmax)
#  returning a pointer to dest.
#  dest is assumed to have room to store nmax bytes.
#  a max of nmax bytes are copied. If a nul byte is encountered before
#    nbytes are copied, the remaining bytes are filled with nul bytes.
#
    move    $v0,$a0
.Lstrncpynext:
    ble $a2,$zero,.Lstrncpydone
    lb  $t0,0($a1)
    sb  $t0,0($a0)
    subi    $a2,$a2,1
    addi    $a0,$a0,1
    addi    $a1,$a1,1
    beq $t0,$zero,.Lstrncpyzeronext
    b   .Lstrncpynext
# we have found a nul byte. Are there more bytes to copy?
# fill the remaining bytes with zeroes.
.Lstrncpyzeronext:
    ble $a2,$zero,.Lstrncpydone
    sb  $zero,0($a0)
    subi  $a2,$a2,1
    addi  $a0,$a0,1
    b   .Lstrncpyzeronext
.Lstrncpydone:
    jr  $ra
    .globl exit
exit:
# implements void exit(void)
# and exits the program with syscall 10
#
    li  $v0,10
    syscall
    # should never return
    jr  $ra
    
#int itoax(unsigned int num, char * string) {
#    
#    // returns 1 (true) unless string is NULL. If string is not NULL,
#    // assumes string has room for the max of 9 characters needed
#    // to convert num to its ASCII hexadecimal counterpart
#    // ALGORITHM: shifts num 8 times to reveal each hex digit.
#    //   skips leading 0 digits
#    int shiftamt=28;  // first shift is 28 bits
#    int thisdig;
#    if (string == NULL) return (0);
#
#    // skip leading zeroes
#    while (((num >> shiftamt) & 0xf)==0) {
#        if (shiftamt == 0) break;
#        shiftamt-=4;
#    }
#    while (shiftamt >= 0) {
#        thisdig=(num >> shiftamt)&0xf;
#        *string++ = itoxc(thisdig);
#        shiftamt -= 4;
#    }
#    *string=0;
#    return(1);
#}
#int itoax(unsigned int num, char * string) {
    .text
    .globl itoax
itoax:
    # this is not a leaf. We need room for our arguments (16)
    # and to save an s-register for the variable shiftamt, as well as $ra (8)
    addiu   $sp,$sp,-24
    sw      $ra,20($sp)
    sw      $s0,16($sp)
#    int shiftamt=28;  // first shift is 28 bits
#    int thisdig;
    addiu   $s0,$zero,28
#    if (string == NULL) return (0);
    bne     $a1,0,.Litoaxdoit
    li      $v0,0
    b       .Litoaxret
#    // skip leading zeroes
#    while (((num >> shiftamt) & 0xf)==0) {
.Litoaxdoit:
#    if (((num >> shiftamt) & 0xf) != 0) goto .Litoaxdigs;
    srlv    $t0,$a0,$s0
    andi    $t0,$t0,0xf
    bne     $t0,$zero,.Litoaxdigs
#        if (shiftamt == 0) break;
    beq     $s0,$zero,.Litoaxdigs
#        shiftamt-=4;
    addiu   $s0,$s0,-4
#    goto .Litaxdoit;
    b       .Litoaxdoit
#    }
.Litoaxdigs:
#    while (shiftamt >= 0) {
#   if (shiftamt < 0) goto .Litoax0
    blt     $s0,$zero,.Litoax0
#        thisdig=(num >> shiftamt)&0xf;
    srlv    $t0,$a0,$s0
    andi    $t0,$t0,0xf
#        *string++ = itoxc(thisdig);
    sw      $a0,24($sp)
    sw      $a1,28($sp)
    move    $a0,$t0
    jal     itoxc
    lw      $a0,24($sp)
    lw      $a1,28($sp)
    sb      $v0,0($a1)
    addi    $a1,$a1,1
#        shiftamt -= 4;
    addiu   $s0,$s0,-4
#   goto .Litoaxdigs
    b       .Litoaxdigs
#    }
.Litoax0:
#    *string=0;
    sb      $zero,0($a1)
#    return(1);
    li      $v0,1
.Litoaxret:
    # unwind stack and return
    lw      $s0,16($sp)
    lw      $ra,20($sp)
    addiu   $sp,$sp,24
    jr      $ra

#char itoxc(int i) {
#    char ch;
#    i &= 0xf;
#    ch = (i + '0');
#    if (i <= 9) goto Ldone
#    ch = 'a' + i - 10;
#Ldone:
#    return (ch);
#}
    .text
    .globl  itoxc
itoxc:
    # leaf procedure - needs no stack frame. Only uses t regs
    # $t0 will be ch
    andi    $a0,$a0,0xf
    addi    $t0,$a0,'0'
    ble     $a0,9,.Litoxcdone
    addi    $t0,$a0,'a'
    addi    $t0,$t0,-10
.Litoxcdone:
    move    $v0,$t0     # should have used $v0 in the beginning.
    jr      $ra


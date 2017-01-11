# The idea of our Sb class is to allow the build-up of a string piecemeal using a character buffer. At any
# point in its construction, the buffer contents can be copied to create a string. The buffer can then
# continue to be appended, or be cleared.
# The purpose of Sb is to minimize the allocation of individual copies of short strings, and the continual
# measuring of lengths. Normally, appending two strings together consists of several steps:
#    1. measure the length of the first string
#    2. measure the length of the second string
#    3. allocate a new area to hold a copy of the two strings concatenated
#    4. copy each string to the new buffer, appending the second string to the first.
#
#
#class Sb {
#    // the buffer is allocated in units of 2^chunk_nbits
#    int chunk_nbits;
#    // the size of the current buffer
#    int buffer_size;
#    // the number of characters in the current buffer
#    int len;
#    char *buffer;
#    // if the current buffer does not have room for the next string, call
#    //   resize, giving it the minimum number of bytes needed. (It rounds up 
#    //   to the next unit of 2^chunk_nbits)
#    void resize(int size_needed, int additional_bytes_wanted);
# public:
#    Sb(void);
#    void append(const char * str);
#    void append(char c);
#    char * toString(void);
#    void clear(void);
#    int length(void);
#};
#
#Sb::Sb(void) {
    .globl Sb$$v
Sb$$v:
    addiu   $sp,$sp,-20
    sw      $ra,16($sp)
    sw      $a0,20($sp)
#   chunk_nbits=5;
    li      $t0,5
    sw      $t0,0($a0)
#    buffer_size=1<<chunk_nbits;
    li      $t0,1
    lw      $t1,0($a0)
    sllv    $t2,$t0,$t1
    sw      $t2,4($a0)
#    buffer = new char[buffer_size];
    move    $a0,$t2
    jal     sbrk
    lw      $a0,20($sp)
    sw      $v0,12($a0)
#    len=0;
    sw      $zero,8($a0)
    lw      $ra,16($sp)
    addiu   $sp,$sp,20
    jr      $ra
#}
# resize allocates a new buffer of minimum size (size_needed + additional_bytes_wanted),
# copies the existing buffer to the new buffer, replaces the current buffer with the new buffer and sets
# len and buffer_size. If there is size_needed bytes remaining in the current buffer, resize
# simply returns.
#void Sb::resize(int size_needed, int additional_bytes_wanted) {
    .globl      Sb$resize$ii
Sb$resize$ii:
    addiu   $sp,$sp,-28
    sw      $ra,24($sp)
    sw      $s1,20($sp) # used for newbuf
    sw      $s0,16($sp) # used for this
#    // need at least size_needed bytes in buffer to
#    // hold resulting string.
#    if (size_needed < buffer_size) return;
    move    $s0,$a0
    lw      $t2,4($s0)  # buffer_size
    blt     $a1,$t2,.Sb$resize$iirtn
#    int size_needed_round = ((size_needed >> chunk_nbits) + 1) << chunk_nbits;
    lw      $t0,0($s0)  # chunk_nbits
    srlv     $t1,$a1,$t0
    addi    $t1,$t1,1
    sllv     $t1,$t1,$t0 # size_needed_round
#    if ((size_needed_round - size_needed) < additional_bytes_wanted) 
#        size_needed_round += (1<<chunk_nbits);
    sub     $t3,$t1,$a1 # (size_needed_round - size_needed)
    bge     $t3,$a2,.Sb$resize$iiskip
    li      $t4,1
    lw      $t5,0($s0)
    sllv    $t5,$t4,$t5 # (1<<chunk_nbits)
    add     $t1,$t1,$t5
.Sb$resize$iiskip:
#    buffer_size=size_needed_round;
    sw      $t1,4($s0)
#    char * newbuf= new char[size_needed_round];
    move    $a0,$t1
    jal     sbrk
    move    $s1,$v0
#    strncpy(newbuf,buffer,len);
    move    $a0,$s1
    lw      $a1,12($s0)
    lw      $a2,8($s0)
    jal     strncpy
#   delete buffer;
#   buffer=newbuf;
    sw      $s1,12($s0)
#}
.Sb$resize$iirtn:
    lw      $s0,16($sp)
    lw      $s1,20($sp)
    lw      $ra,24($sp)
    addiu   $sp,$sp,28
    jr      $ra
#

# the append functions append either a string or a single character to the current buffer, updating len
# appropriately. They call resize if there is not enough room in the current buffer to add the data.
#   void append (const char *str);
   .globl Sb$append$C
Sb$append$C:
    addiu   $sp,$sp,-24
    sw      $ra,20($sp)
    sw      $s0,16($sp) 
    sw      $a1,28($sp)
    
    move    $s0,$a0 
    move    $a0,$a1
    jal strlen
    
    lw      $a1,8($s0)
    add     $a1,$a1, $v0
    lw      $a2,4($s0)
    sub     $a2,$a1, $a2    
    move    $a0,$s0    
    jal Sb$resize$ii
    
    lw      $a0,12($s0) 
    lw      $t0,8($s0)
    add     $a0,$a0, $t0
    lw      $a1,28($sp)
    lw      $a2,4($s0)
    jal strncpy  
    
    lw      $a0,12($s0)
    jal strlen
    sw      $v0,8($s0)
    
    lw      $s0,16($sp)
    lw      $ra,20($sp)
    addiu   $sp,$sp,24
    jr      $ra
    
#   void append (const char c);
   .globl Sb$append$c
Sb$append$c:
    addiu   $sp,$sp,-24
    sw      $ra,20($sp)       
    sw      $s0,16($sp) 
    sb      $a1,28($sp)
    
    move    $s0,$a0   
    lw      $a1,8($s0)
    addi    $a1,$a1, 2
    lw      $a2,4($s0)
    sub     $a2,$a1,$a2
    jal Sb$resize$ii
    
    lw      $t0,12($s0)
    lw      $t1,8($s0)
    add     $t2,$t0,$t1
    lb      $a1,28($sp)
    sb      $a1,0($t2)
    sb      $zero,1($t2)
    addi    $t1,$t1,1
    sw      $t1,8($s0)
    
    lw      $s0,16($sp)
    lw      $ra,20($sp)
    addiu   $sp,$sp,24
    jr      $ra
#
# toString copies the contents of the current buffer to a newly allocated area, null-terminates the
# new data and returns the new data. The current contents of the buffer are unchanged.    
#    char *toString( void )
    .globl Sb$toString$v
Sb$toString$v:    
    addiu   $sp,$sp,-24
    sw      $ra,20($sp)
    sw      $s0,16($sp)
    move    $s0,$a0
    
    lw      $a0,8($s0)
    addi    $a0,$a0,1
    jal sbrk
    
    lw      $a1,12($s0)
    move    $a0,$v0
    lw      $a2,8($s0)
    addi    $a2,$a2,1
    jal strncpy
    
    lw      $s0,16($sp)
    lw      $ra,20($sp)
    addiu   $sp, $sp, 24
    jr      $ra

# clear simply sets the number of characters in the buffer to zero.
#   void clear (void)
    .globl Sb$clear$v
Sb$clear$v:
    sw      $zero,8($a0)
    jr      $ra 

# length simply returns the number of characters in the current buffer    
#   int length (void)  
    .globl Sb$length$v
Sb$length$v:
    lw      $v0,8($a0)    
    jr      $ra        
        
# a main program,
# does the following:
# 1. allocates and constructs an Sb object
# 2. asks the user to enter a string. 
# 3. If the string is empty, the current buffer is copied to a new string and output in a message. Then
# the user is asked if they want to clear the buffer, quit, or continue. Unless quitting, repeat at 2.
# 4. Otherwise, if the input is multi-character, the string is appended to the buffer. If the input is a
# single character, the single character is appended to the buffer. Then repeat at 2.
#                
.data
prompt1: .asciiz "Input next string(q to quit, empty for result):"
prompt2: .asciiz "Result string: "
prompt3: .asciiz "Clear buffer?(y/n/q):"
     .align 2
BUF_MAX: .word 100        
#define BUF_MAX 100
#main() {
    .text
    .globl main
main:    
    addiu   $sp,$sp,-32
    sw      $ra,28($sp)
    sw      $s0,16($sp) # nb
    sw      $s1,20($sp) # *buffer 
    sw      $s2 24($sp) # *mysb
#  Sb *mysb = new Sb;
    li      $a0,16
    jal sbrk 
    move    $s2,$v0
    move    $a0,$v0
    jal Sb$$v
#   char *buffer = new char[BUF_MAX];
    lw 	    $a0,BUF_MAX
    jal sbrk
    move    $s1,$v0
 MainLoop:   
#   while (1) {
#   int nb= InputDialogString("Input next string(q to quit, empty for result):",buffer,BUF_MAX);
    la      $a0,prompt1
    move    $a1,$s1
    lw      $a2,BUF_MAX
    jal InputDialogString
    move    $s0,$v0
#   if (nb<0) break;
    bge     $s0,$zero,A$skip
    b LoopEnd	
 A$skip:	
#   if (nb==0) {
    bnez    $s0,B$skip
#   MessageDialogString("Result string: ",mysb->toString());	
    move    $a0,$s2 
    jal Sb$toString$v
    move    $a1,$v0
    la      $a0,prompt2
    jal MessageDialogString
#   nb= InputDialogString("Clear buffer?(y/n/q):",buffer,BUF_MAX);
    la      $a0,prompt3
    move    $a1,$s1
    lw      $a2,BUF_MAX
    jal InputDialogString
    move    $s0,$v0
#   if (nb<0) break;
    bge     $s0,$zero,C$skip
    b LoopEnd
C$skip: 	
#   if (buffer[0] == 'y') mysb->clear(); 
    lb      $t0,0($s1)
    bne     $t0,'y',CSkip
    move    $a0,$s2
    jal Sb$clear$v
#   continue;     
CSkip: 
    b MainLoop
#}
 B$skip:
#   if (nb==1) mysb->append(buffer[0]);
    li      $t0,1
    bne     $s0,$t0,D$skip
    lb      $a1,0($s1)
    move    $a0,$s2
    jal Sb$append$c
    b MainLoop
D$skip: 	 
#   else mysb->append(buffer);
    move    $a1,$s1
    move    $a0,$s2
    jal Sb$append$C
    b MainLoop
#  }
#}
LoopEnd:     
    lw      $s0,16($sp)
    lw      $s1,20($sp)  
    lw      $s2 24($sp) 
    lw      $ra,28($sp)
    addiu   $sp,$sp,32
    jr      $ra
    


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


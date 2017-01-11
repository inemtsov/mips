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
    
#.include "/pub/cs/gboyd/cs270/util.s"
.include "/Users/nemtsovilya/util.s"

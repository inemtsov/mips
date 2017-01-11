A simple object-oriented program in assembler. In it, i implement a class similar to a simplified version of the StringBuilder class in Java, named Sb. The
higher-level code, however, will be in C++.
Description:
The idea of our Sb class is to allow the build-up of a string piecemeal using a character buffer. At any point in its construction, the buffer contents can be copied to create a string. The buffer can then
continue to be appended, or be cleared. The purpose of Sb is to minimize the allocation of individual copies of short strings, and the continual
measuring of lengths. Normally, appending two strings together consists of several steps:
1. measure the length of the first string
2. measure the length of the second string
3. allocate a new area to hold a copy of the two strings concatenated
4. copy each string to the new buffer, appending the second string to the first.
Although smart compilers should be able to optimize this, if the build of a string occurs in a loop, it is incredibly wasteful. Instead, using our Sb class, we use a preallocated buffer to copy the pieces to,
keeping track of the current length of the string in the buffer. In this case, the entire string only needs copying when we want a copy or when the preallocated buffer runs out of room and it must be copied to
a new larger buffer before continuing.

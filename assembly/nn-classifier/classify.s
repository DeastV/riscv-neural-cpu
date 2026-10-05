# ===========================================================
# 2-Layer Neural Network Forward Propagation Classifier
# Authors: Guilherme Marques, David Vasques
# ===========================================================

# Top-5 das otimizacoes que a vossa solucao incorpora:
# (maximo 140 caracteres por cada otimizacao)
#
# 1. Reutilização de ponteiros e minimização de acessos à memória para maior eficiência computacional.
# 2. Conversão direta de bytes para inteiros com offsets otimizados, reduzindo instruções redundantes.
# 3. Matriz-multiplicação otimizada com uso explícito de registradores e controle manual de índices.
# 4. Implementação in-place da função ReLU, evitando alocação e cópia desnecessárias.
# 5. Utilização eficiente da stack para preservação/restauração de contexto em chamadas de funções.
# ===========================================================

.data

# ===========================================================
#Main data structures. These definitions cannot be changed.

h_m0: .word 128
w_m0: .word 784
m0: .zero 401408                #h_m0 * w_m0 * 4 bytes

h_m1: .word 10
w_m1: .word 128
m1: .zero 5120                  #h_m1 * w_m1 * 4 bytes

h_input: .word 784
w_input: .word 1
input: .zero 3136               #h_input * w_input * 4 bytes

h_h: .word 128
w_h: .word 1
h: .zero 512                    #h_h * w_h * 4 bytes

h_o: .word 10
w_o: .word 1
o: .zero 40                     #h_o * w_o * 4 bytes


# ===========================================================
filename_m0:    .string "m0.bin"
filename_m1:    .string "m1.bin"
filename_input: .string "input8.bin"

m0_bytes: .word 100352     # 128*784 bytes
m1_bytes: .word 1280       # 10*128 bytes
input_bytes: .word 784 
# ===========================================================
.text

main:
    # Call the name of the files
    la a0, filename_m0     # m0
    la a1, filename_m1     # m1
    la a2, filename_input  # input

    # Call classify (the result will be stored in a0)
    call classify

    # Print the value stored in a0
    li a7, 1           # Syscall code to print
    ecall

    # Finishis the programme
    li a7, 10          # Syscall code to exit
    ecall

# ===========================================================
# FUNCTION: abs
#   Computes absolute value of the int stored at a0
# Arguments:
#   a0, a pointer to int
# Returns:
#   Nothing (modifies value in memory)
# ===========================================================

abs:
  lw t0, 0(a0)         # Load int value
  bltz t0, pos         # If value >= 0, skip the number negation
  neg t0, t0           # t0 = -t0
  sw t0, 0(a0)         # Store back to memory

pos:
    neg t0, t0         #makes the number positive
    sw t0, 0(a0)       #switches the value
    
    jr ra              # Return to the caller



# ============================================================
# FUNCTION: relu
#   Applies ReLU on each element of the array (in-place)
# Arguments:
#   a0 = pointer to int array
#   a1 = array length
# Exceptions:
#   - If the length of the array is less than 1,
#     this function terminates the program with error code 36
# ============================================================
relu:
  li t0, 1                     # Load 1 into t0
  blt a1, t0, error_36         # If array length a1 < 1, jump to error

  li t1, 0                     # Initialize index i = 0

loop_relu:
  beq t1, a1, loop_end_relu    # If i == length, end loop

  slli t2, t1, 2               # Compute byte offset: t2 = i * 4
  add t3, a0, t2               # Get address of array[i]
  lw t4, 0(t3)                 # Load array[i] into t4

  bge t4, zero, next           # If value >= 0, skip zeroing
  sw zero, 0(t3)               # Else, set array[i] = 0

next:
  addi t1, t1, 1               # i++
  j loop_relu                  # Repeat loop

error_36:
  li a0, 36                    # Set error code 36
  j exit_with_error            # Jump to error handler

loop_end_relu:
  jr ra                        # Return to caller



# =================================================================
# FUNCTION: Given an int array, return the index of the largest
#   element. If there are multiple, return the one
#   with the smallest index.
# Arguments:
#   a0 (int*) is the pointer to the start of the array
#   a1 (int)  is the number of elements in the array
# Returns:
#   a0 (int)  is the first index of the largest element
# Exceptions:
#   - If the length of the array is less than 1,
#     this function terminates the program with error code 37
# =================================================================
argmax:
    li t0, 1                    # Load 1 into t0
    blt a1, t0, bad_length      # If length (a1) < 1, jump to error

    li t1, 1                    # Initialize index counter (t1 = 1)
    li t2, 0                    # Store max index found so far (t2 = 0)
    lw t3, 0(a0)                # Load first element as current max value (t3)

loop_argmax:
    beq t1, a1, loop_end_argmax  # If index == length, end loop

    lw t4, 4(a0)                # Load next element (current candidate) into t4
    ble t4, t3, skip            # If t4 <= max so far, skip update

    mv t3, t4                   # Update max value to t4
    mv t2, t1                   # Update max index to current index

skip:
    addi t1, t1, 1              # Increment index
    addi a0, a0, 4              # Move to next array element
    j loop_argmax              # Repeat loop

bad_length:
    li a0, 37                   # Set error code 37
    j exit_with_error           # Jump to error handler

loop_end_argmax:
    mv a0, t2                   # Move max index to return register
    jr ra                       # Return to caller




# =======================================================
# FUNCTION: Dot product of 2 int arrays
# Arguments:
#   a0 (int*) - Pointer to the start of arr0
#   a1 (int*) - Pointer to the start of arr1
#   a2 (int)  - Number of elements to use   
# Returns:
#   a0 (int)  - The dot product of arr0 and arr1
# Exceptions:
#   - If a2 < 1, exit with error code 38
# =======================================================
dotproduct:
    blez a2, exit_with_error   # Exit with error if number of elements (a2) <= 0
    li t3, 0                   # Initialize accumulator (t3 = 0)

loop_dotproduct:
    beqz a2, done_dotproduct   # If counter a2 == 0, we're done
    lw t0, 0(a0)               # Load current element from first array into t0
    lw t1, 0(a1)               # Load current element from second array into t1
    mul t2, t0, t1             # Multiply elements: t2 = t0 * t1
    add t3, t3, t2             # Accumulate: t3 += t2

    addi a0, a0, 4             # Move to next element in first array
    addi a1, a1, 4             # Move to next element in second array
    addi a2, a2, -1            # Decrement element counter
    j loop_dotproduct          # Repeat loop

done_dotproduct:
    mv a0, t3                  # Move accumulated result to a0 (function return value)
    jr ra                      # Return to caller



# =======================================================
# FUNCTION: Matrix Multiplication of 2 integer matrices
#   d = matmul(m0, m1)
#
# Arguments:
#   a0 (int*)  - pointer to the start of m0     (Matrix A)
#   a1 (int*)  - pointer to the start of m1     (Matrix B)
#   a2 (int)   - number of rows in m0 (A)             [rows_A]
#   a3 (int)   - number of columns in m0 (A)          [cols_A]
#   a4 (int)   - number of rows in m1 (B)             [rows_B]
#   a5 (int)   - number of columns in m1 (B)          [cols_B]
#   a6 (int*)  - pointer to the start of d            (Matrix C = A x B)
#
# Returns:
#   None (void); result is stored in memory pointed to by a6 (d)
#
# Exceptions:
#  - If the height or width of any of the matrices is less than 1, 
#    this function terminates the program with error core 39
#  - If the number of columns in matrix A is not equal to the number 
#    of rows in matrix B, it terminates with error code 40
# =======================================================
matmul:
  li t0, 1                         # Load immediate 1 into t0
  blt a2, t0, error_39             # If a2 (rows of A) < 1, jump to error_39
  blt a3, t0, error_39             # If a3 (cols of A) < 1, jump to error_39
  blt a4, t0, error_39             # If a4 (rows of B) < 1, jump to error_39
  blt a5, t0, error_39             # If a5 (cols of B) < 1, jump to error_39
  bne a3, a4, error_40             # If cols of A ≠ rows of B, invalid matmul, jump to error_40

  li t0, 0                         # Set outer loop index i = 0
dotproduct_matmul:
  bge t0, a2, done_matmul          # If i >= rows of A, matrix multiplication is done
  li t1, 0                         # Set inner loop index j = 0
loop_rows:
  bge t1, a5, next_row               # If j >= cols of B, go to next row of A

  li t2, 0                         # t2 = accumulator for dot product
  li t3, 0                         # k index for dot product
loop_cols:
  bge t3, a3, store_result         # If k >= cols of A, store dot product result

  mul t4, t0, a3                   # t4 = i * cols_A
  add t4, t4, t3                   # t4 = i * cols_A + k
  slli t4, t4, 2                   # t4 *= 4 (byte offset)
  add t5, a0, t4                   # t5 = address of A[i][k]
  lw t4, 0(t5)                     # Load A[i][k] into t4

  mul t5, t3, a5                   # t5 = k * cols_B
  add t5, t5, t1                   # t5 = k * cols_B + j
  slli t5, t5, 2                   # t5 *= 4 (byte offset)
  add t6, a1, t5                   # t6 = address of B[k][j]
  lw t5, 0(t6)                     # Load B[k][j] into t5

  mul t4, t4, t5                   # Multiply A[i][k] * B[k][j]
  add t2, t2, t4                   # Accumulate into dot product (t2 += A[i][k] * B[k][j])

  addi t3, t3, 1                   # k++
  j loop_cols                         # Repeat for next k

store_result:
  mul t4, t0, a5                   # t4 = i * cols_B
  add t4, t4, t1                   # t4 = i * cols_B + j
  slli t4, t4, 2                   # t4 *= 4 (byte offset)
  add t5, a6, t4                   # t5 = address of C[i][j]
  sw t2, 0(t5)                     # Store dot product result into C[i][j]

  addi t1, t1, 1                   # j++
  j loop_rows                         # Repeat for next column j

next_row:
  addi t0, t0, 1                   # i++
  j dotproduct_matmul              # Repeat for next row i

done_matmul:
  jr ra                            # Return from function

error_39:
  li a0, 39                        # Load error code 39 (invalid dimensions)
  j exit_with_error                # Jump to error handler

error_40:
  li a0, 40                        # Load error code 40 (incompatible dimensions)
  j exit_with_error                # Jump to error handler

######################################################################
# Function: read_file(char* filename, byte* buffer, int length)
# Input:
#   a0: pointer to null-terminated filename string
#   a1: destination buffer
#   a2: number of bytes to read
# Output:
#   a0: number of bytes read (return value from syscall)
# Exceptions:
#   - Error code 41 if error in the file descriptor
#   - Error code 42 If the length of the bytes to read is less than 1
######################################################################
    
read_file:
    # Save registers we'll modify (except a0 which is the return value)
    addi sp, sp, -12           # Make space on the stack
    sw ra, 0(sp)               # Save return address
    sw s1, 4(sp)               # Save s1 (file descriptor)
    sw s2, 8(sp)               # Save s2 (buffer pointer)
    
    # Check if length is valid
    li t0, 1                   # Load constant 1
    blt a2, t0, invalid_length # If length (a2) < 1, jump to error
    
    mv s2, a1                  # Save buffer pointer (a1) into s2
    
    # Open file (a0 already contains filename)
    li a1, 0                   # Flags = 0 (read-only)
    li a7, 1024                # Syscall number for open
    ecall                      # Perform system call to open file
    
    # Check if file opened successfully
    blt a0, zero, open_error   # If file descriptor < 0, jump to error
    
    mv s1, a0                  # Save file descriptor in s1
    
    # Read file (a0 = fd, a1 = buffer, a2 = length)
    mv a0, s1                  # Move fd into a0
    mv a1, s2                  # Restore buffer pointer into a1
    li a7, 63                  # Syscall number for read
    ecall                      # Perform system call to read file
    
    # Save return value (number of bytes read)
    mv t0, a0                  # Store read byte count in t0
    
    # Close file
    mv a0, s1                  # Move fd into a0 for closing
    li a7, 57                  # Syscall number for close
    ecall                      # Perform system call to close file
    
    # Return number of bytes read
    mv a0, t0                  # Move byte count into a0 (return value)
    j read_file_end            # Skip to cleanup and return
    
open_error:
    li a0, 41                  # Load error code for open failure
    j exit_with_error          # Jump to error handler
    
invalid_length:
    li a0, 42                  # Load error code for invalid length
    j exit_with_error          # Jump to error handler
    
read_file_end:
    # Epilogue - restore registers
    lw ra, 0(sp)               # Restore return address
    lw s1, 4(sp)               # Restore s1
    lw s2, 8(sp)               # Restore s2
    addi sp, sp, 12            # Deallocate stack space
    
    jr ra                      # Return to the caller

# =======================================================
# FUNCTION: Convert array of bytes (chars) to integers
#   turn_int(src, dst, length, offset, flag)
#
# Arguments:
#   a0 (byte*)   - pointer to source byte array (adjusted by offset)
#   a1 (int*)    - pointer to destination integer array
#   a2 (int)     - length of the array
#   a3 (int)     - byte offset added to source pointer before processing
#   a4 (int)     - flag to decide whether to subtract 32 from each byte
#
# Returns:
#   (void) - result written in destination array as 32-bit integers
#
# Description:
#   Loads each byte from source array, optionally subtracts 32 depending
#   on flag, then stores the result as an integer in destination array.
# =======================================================

turn_int:
    li t1, 0                  # Initialize index t1 = 0
    add a0, a0, a3            # Adjust source pointer by offset a3

loop_turn_int:
    add t3, t1, a0            # Calculate address of current byte: src + index
    lb t0, 0(t3)              # Load byte from source array

    slli t4, t1, 2            # Calculate destination offset: index * 4 (int size)
    add t3, t4, a1            # Calculate address of destination int: dst + offset
    ble a4, x0, skip_process  # If flag a4 <= 0, skip subtraction
    addi t0, t0, -32          # Else subtract 32 from byte value

skip_process:
    sw t0, 0(t3)              # Store processed byte as int in destination array
    addi t1, t1, 1            # Increment index
    blt t1, a2, loop_turn_int     # Repeat loop while index < length

    jr ra                     # Return from function


# =======================================================
# FUNCTION: Classify decimal digit from input image
#   d = classify(A, B, input)
#
# Arguments:
#   a0 (string*)  - pathname of file with the weight matrix m0
#   a1 (string*)  - pathname of file with the weight matrix m1
#   a2 (string*)  - pathname of file with the input image in Raw PGM format
#
# Returns:
#   a0 (int) - value of the classified decimal digit
#
# =======================================================

classify:
    # Save return address and filenames on stack
    addi sp, sp, -16
    sw ra, 0(sp)
    sw a1, 4(sp)     # save filename_m1
    sw a2, 8(sp)     # save filename_input

    # -------------------------------------
    # Step 1: Read files into memory
    # -------------------------------------

    # Read m0 file into m0_bytes buffer
    la a1, m0_bytes
    li a2, 100352    # size = 128*784*4 bytes
    call read_file
    
    # Convert raw m0_bytes to integer matrix m0
    la a0, m0_bytes
    la a1, m0
    li a2, 100352
    li a3, 0         # offset
    li a4, 1         # flag for conversion
    call turn_int

    # Read m1 file into m1_bytes buffer
    lw a0, 4(sp)     # filename_m1
    la a1, m1_bytes
    li a2, 1280      # size = 1280 bytes
    call read_file
    
    # Convert raw m1_bytes to integer matrix m1
    la a0, m1_bytes
    la a1, m1
    li a2, 1280
    li a3, 0
    li a4, 1
    call turn_int

    # Read input image file into input_bytes buffer
    lw a0, 8(sp)     # filename_input
    la a1, input_bytes
    li a2, 796       # size = 784 bytes
    call read_file
    
    # Convert raw input_bytes to integer vector input
    la a0, input_bytes
    la a1, input
    li a2, 784
    li a3, 12        # offset for input casting
    li a4, 0         # flag for conversion
    call turn_int

    # -------------------------------------
    # Step 2: Compute h = ReLU(matmul(m0, input))
    # -------------------------------------
    la a0, m0        # matrix A pointer
    la a1, input     # vector B pointer
    lw a2, h_m0      # rows in m0
    lw a3, w_m0      # cols in m0
    lw a4, h_input   # rows in input vector
    lw a5, w_input   # cols in input vector
    la a6, h         # output buffer for h
    call matmul      # matrix multiplication

    # Apply ReLU activation on h
    la a0, h
    lw a1, h_h       # length of h
    call relu

    # -------------------------------------
    # Step 3: Compute o = matmul(m1, h)
    # -------------------------------------
    la a0, m1
    la a1, h
    lw a2, h_m1      # rows in m1
    lw a3, w_m1      # cols in m1
    lw a4, h_h       # rows in h
    lw a5, w_h       # cols in h
    la a6, o         # output buffer for o
    call matmul

    # -------------------------------------
    # Step 4: Find argmax of output o
    # -------------------------------------
    la a0, o
    lw a1, h_o       # length of o
    call argmax      # returns index of max value in a0

    # Restore stack and return
    lw ra, 0(sp)
    addi sp, sp, 16
    jr ra


# =======================================================
# Exit procedures
# =======================================================

# Exits the program (with code 0)
exit:
    li a7, 10     # Exit syscall code
    ecall         # Terminate the program

# Exits the program with an error 
# Arguments: 
# a0 (int) is the error code 
# You need to load a0 the error to a0 before to jump here
exit_with_error:
  li a7, 93            # Exit system call
  ecall                # Terminate program
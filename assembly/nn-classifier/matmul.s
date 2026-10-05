.data

# You can change this array to test other values (remember to modify the dimentions in the main)
m0: .word 1, 2, 3, 4, 5, 6        # Matrix A (2x3) in row-major order
m1: .word 7, 8, 9, 10, 11, 12     # Matrix B (3x2) in row-major order
d:  .word 0, 0, 0, 0              # Output matrix C (2x2), initialized to 0

.text
main:
  # Load pointers to matrices
  la a0, m0                     # a0 = address of matrix A
  la a1, m1                     # a1 = address of matrix B
  la a6, d                      # a6 = address of output matrix C

  # Load matrix dimensions
  li a2, 2                      # a2 = rows of A = 2
  li a3, 3                      # a3 = cols of A = 3
  li a4, 3                      # a4 = rows of B = 3
  li a5, 2                      # a5 = cols of B = 2
  
  # Load input type 
  jal ra, matmul                # Call matrix multiplication function

  # The contents of matrix d now have the result of matmul(m0,m1)

exit:
  li a7, 10              # Exit syscall code
  ecall                  # Terminate the program

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
#    this function terminates the program with error core 38
#  - If the number of columns in matrix A is not equal to the number 
#    of rows in matrix B, it terminates with error code 38
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

# Exits the program with an error 
# Arguments: 
# a0 (int) is the error code 
# You need to load a0 the error to a0 before to jump here
exit_with_error:
  li a7, 93            # Exit system call
  ecall                # Terminate program


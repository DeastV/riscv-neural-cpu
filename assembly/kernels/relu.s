.data
# You can change this array to test other values
array: .word -3, 2, -1, 7, -2   # Initial array values				 

.text

main:
  la a0, array      # a0 = pointer to array
  li a1, 5          # a1 = number of elements in the array

  jal ra, relu      # Call relu function

  # Result: the array now has its negative values replaced by zero

exit:
  li a7, 10              # Exit syscall code
  ecall                  # Terminate the program


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
  # Check if a1 < 1
  li t0, 1
  blt a1, t0, error_36   # if a1 < 1, go to error

  li t1, 0                 # index i = 0

loop:
  beq t1, a1, loop_end     # if i == n, the loop ends

  slli t2, t1, 2           # t2 = i * 4 (offset in bytes)
  add t3, a0, t2           # t3 = rray[i] pointer
  lw t4, 0(t3)             # t4 = current value

  bge t4, zero, next       # if value >= 0, skips
  sw zero, 0(t3)           # else, writes 0

next:
  addi t1, t1, 1           # i++
  j loop

error_36:
  li a0, 36
  j exit_with_error

loop_end:
  jr ra                  # normal return


# Exits the program with an error 
# Arguments: 
# a0 (int) is the error code 
# You need to load a0 the error to a0 before to jump here
exit_with_error:
  li a7, 93            # Exit system call (with code)
  ecall
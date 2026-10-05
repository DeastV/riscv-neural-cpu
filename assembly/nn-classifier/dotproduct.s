.data
# Sample input arrays
# You can change this array to test other values (remember to modify the dimensions in the main)

arr0: .word 1, 2, 3, 4, 5, 6, 7, 8, 9
arr1: .word 6, 1, 6, 1, 6, 1, 6, 1, 6

.text

main:	
    # Set up arguments for dotproduct(arr0, arr1, 9)
    la a0, arr0         # a0 = &arr0
    la a1, arr1         # a1 = &arr1
    li a2, 9            # a2 = number of elements
    
    jal ra, dotproduct  # Call dotproduct function

exit:
    li a7, 10           # Exit syscall code
    ecall               # Terminate the program

# =======================================================
# FUNCTION: Dot product of 2 int arrays
# Arguments:
#   a0 (int*) - Pointer to arr0
#   a1 (int*) - Pointer to arr1
#   a2 (int)  - Number of elements
# Returns:
#   a0 (int)  - Dot product result
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
exit_with_error:
    li a7, 93                  # Exit syscall
    ecall
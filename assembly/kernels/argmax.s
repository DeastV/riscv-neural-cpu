.data
# You can change this array to test other values
array: .word 1, 9, 3, 7, 2   # Initial array values

.text

main:
    la a0, array           # Load address of the array
    li a1, -5               # Number of elements in the array

    jal ra, argmax         # Call the argmax function

    # Result: the index of the largest element is now in a0

exit:
    li a7, 10              # Exit syscall code
    ecall                  # Terminate the program


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
#     this function terminates the program with error code 36
# =================================================================
argmax:
    # If the lenght of the array is < 1, returns error
    li t0, 1                    
    blt a1, t0, bad_length    
    
    # Initiate Variables
    li t1, 1                  # Current index
    li t2, 0                  # Current max index
    lw t3, 0(a0)              # Current max digit, starting 

loop:
    # Check if the current index is equal to the lenght of the array
    beq t1, a1, loop_end
    
    # If current digit is <= to the current max digit, skips it
    lw t4, 4(a0)              # Load the current digit
    ble t4, t3, skip
     
    # Updates the current max index and max digit 
    mv t3, t4             
    mv t2, t1
    
skip:
    # Uptades to the next index and digit and jumps back to loop
    addi t1, t1, 1
    addi a0, a0, 4
    j loop
    

bad_length:
    # Updates the a0 to 36 and jumps to exits_with_error
    li a0, 36
    j exit_with_error


loop_end:
    mv a0, t2                    # Updates a0 to the current max index 
    jr ra                        # Return to the caller

# Exits the program with an error 
# Arguments: 
# a0 (int) is the error code 
# You need to load a0 the error to a0 before to jump here
exit_with_error:
    li a7, 93                    # Exit system call
    ecall                        # Terminate program

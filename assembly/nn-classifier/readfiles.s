.data

buffer_input:   .zero 3196
null:           .string ""
file_input:     .string "input0.bin"

.text

main:
    # Read file into buffer_input
    la  a0, file_input       # a0 = pointer to filename
    la  a1, buffer_input     # a1 = pointer to buffer
    li  a2, 3196             # a2 = number of bytes to read
    jal ra, read_file        # call read_file

    # Print the contents of buffer_input to stdout
    la a1, buffer_input      # a1 = buffer to print
    mv a2, a0                # a2 = number of bytes read (returned in a0)
    li a0, 1                 # a0 = file descriptor 1 (stdout)
    li a7, 64                # syscall number for write
    ecall                    # perform write syscall

    # Exit program
    li a7, 10                # syscall: exit
    ecall

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
#   - Error code 42 if the length of the bytes to read is less than 1
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

# Exits the program with an error 
# Arguments: 
# a0 (int) is the error code 
exit_with_error:
    li a7, 93                  # Exit system call
    ecall                      # Terminate program

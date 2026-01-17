# Simple TCL script - works on Windows without serial package
# Uses Windows COM port directly via tclsh

# For Windows: Use native file operations to access COM port
proc send_to_fpga {number} {
    set com_port "COM5"
    
    # Validate input
    if {![string is integer -strict $number]} {
        puts "Error: Please enter a number between 0 and 255"
        return 0
    }
    
    set number [expr {$number & 0xFF}]
    
    # Try to open COM port
    if {[catch {
        set port [open $com_port w]
    } err]} {
        puts "Error: Cannot open $com_port"
        puts "Fix: Check Device Manager for correct COM port number"
        puts "Edit this script and change: set com_port \"COMX\""
        return 0
    }
    
    # Configure port for binary output
    fconfigure $port -translation binary -buffering none
    
    # Send byte
    catch {puts -nonewline $port [binary format c $number]}
    catch {flush $port}
    
    close $port
    
    puts "Sent: $number (0x[format %02X $number]) to $com_port"
    return 1
}

# Main loop
puts "===== FPGA Number Sender ====="
puts "Type numbers 0-255 to send to FPGA"
puts "Type 'quit' to exit"
puts ""

while {1} {
    puts -nonewline "> "
    flush stdout
    
    gets stdin input
    
    if {$input eq "quit" || $input eq "exit"} {
        puts "Goodbye!"
        break
    }
    
    send_to_fpga $input
}

# TCL script to send numbers to FPGA via UART
# This will display numbers on the HDMI screen

# Configure your COM port here (check Device Manager)
set COM_PORT "COM6"
set BAUD_RATE 115200

# Open serial port
puts "Opening $COM_PORT at $BAUD_RATE baud..."
if {[catch {set port [open $COM_PORT r+]} err]} {
    puts "Error opening port: $err"
    puts "Please check:"
    puts "  1. COM port number in Device Manager"
    puts "  2. No other program is using the port"
    puts "  3. USB cable is connected"
    exit 1
}

# Configure port
fconfigure $port -mode "$BAUD_RATE,n,8,1" -buffering none -translation binary

puts "Connected to FPGA!"
puts "Commands:"
puts "  Type a number (0-255) to display on screen"
puts "  Type 'quit' to exit"
puts ""

# Interactive loop
while {1} {
    puts -nonewline "Number> "
    flush stdout
    
    gets stdin input
    
    # Check for quit command
    if {$input eq "quit" || $input eq "exit"} {
        puts "Closing connection..."
        break
    }
    
    # Validate input is a number
    if {![string is integer -strict $input]} {
        puts "Error: Please enter a number between 0 and 255"
        continue
    }
    
    set number [expr {$input}]
    
    # Check range
    if {$number < 0 || $number > 255} {
        puts "Error: Number must be between 0 and 255"
        continue
    }
    
    # Send byte to FPGA
    puts -nonewline $port [binary format c $number]
    flush $port
    
    puts "Sent: $number (0x[format %02X $number]) - Check HDMI display!"
}

close $port
puts "Disconnected from FPGA"

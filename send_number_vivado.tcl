# TCL script for Vivado to send numbers to FPGA via UART
# Run this from Vivado's TCL Console instead of command line

proc send_uart_number {number} {
    # Validate input
    if {![string is integer -strict $number]} {
        puts "Error: Please enter a number between 0 and 255"
        return
    }
    
    set number [expr {$number}]
    
    if {$number < 0 || $number > 255} {
        puts "Error: Number must be between 0 and 255"
        return
    }
    
    # Open hardware target
    if {[catch {
        open_hw_manager
    } err]} {
        puts "Hardware manager already open"
    }
    
    # Connect to board
    if {[catch {
        connect_hw_server
    } err]} {
        puts "Hardware server already connected"
    }
    
    if {[catch {
        open_hw_target
    } err]} {
        puts "Hardware target already open"
    }
    
    # Get the current device
    set devices [get_hw_devices]
    if {[llength $devices] == 0} {
        puts "Error: No FPGA devices found. Program your FPGA first!"
        return
    }
    
    set device [lindex $devices 0]
    current_hw_device $device
    
    # Try to write to VIO probe if it exists
    set probes [get_hw_probes]
    
    if {[llength $probes] > 0} {
        # Use first available probe to send data
        set probe [lindex $probes 0]
        puts "Sending $number to $probe..."
        set_property OUTPUT_VALUE $number $probe
        commit_hw_vio $probe
        puts "Sent: $number (0x[format %02X $number]) - Check HDMI display!"
    } else {
        puts "Note: No VIO probes found. Make sure your FPGA design has VIO (Virtual I/O) core."
        puts "For direct serial communication, see send_number_serial.tcl"
    }
}

# Interactive mode
puts "===== FPGA UART Number Sender ====="
puts "Commands:"
puts "  send_uart_number 42      - Send number 42 to FPGA"
puts "  send_uart_number 255     - Send number 255"
puts ""
puts "Example: send_uart_number 100"
puts ""

# Send a test number if desired
if {[info exists argv] && [llength $argv] > 0} {
    send_uart_number [lindex $argv 0]
}

# vivado_color_control.tcl
# Run on Vivado laptop to programmatically change line color
# Usage: Run from Vivado TCL Console OR: vivado -mode batch -source vivado_color_control.tcl

proc set_line_color {color_value} {
    # color_value: 0=BLUE, 1=GREEN, 2=RED
    
    if {$color_value < 0 || $color_value > 2} {
        puts "ERROR: Color must be 0 (BLUE), 1 (GREEN), or 2 (RED)"
        return 0
    }
    
    set color_names [list "BLUE" "GREEN" "RED"]
    set color_name [lindex $color_names $color_value]
    
    puts "Setting line color to: $color_name ($color_value)"
    
    # Make sure hardware is connected
    if {[catch {
        set_property OUTPUT_VALUE $color_value [get_hw_probes vio_0/probe_out0]
        commit_hw_vio [get_hw_probes vio_0/probe_out0]
        puts "✓ Color changed successfully!"
        return 1
    } err]} {
        puts "ERROR: Could not set color: $err"
        puts "Make sure:"
        puts "  1. FPGA is programmed with VIO core"
        puts "  2. Hardware manager is open and connected"
        puts "  3. VIO probe is named 'vio_0/probe_out0'"
        return 0
    }
}

# ============================================
# EXAMPLE: Change color based on computation
# ========
====================================

proc compute_color {} {
    # Do your computation here (temperature, signal level, etc.)
    # For now, just a simple example
    
    set current_time [clock seconds]
    set remainder [expr {$current_time % 3}]
    
    # Cycle through colors based on time
    switch $remainder {
        0 { return 0 }  ;# BLUE
        1 { return 1 }  ;# GREEN
        2 { return 2 }  ;# RED
    }
}

# ============================================
# MAIN: Loop and update color based on logic
# ============================================

puts "Starting color controller..."
puts "Press Ctrl+C to stop"
puts ""

set iteration 0
while {1} {
    incr iteration
    
    # Your computation/logic here
    set color [compute_color]
    
    # Example: Different color based on counter
    # if {$iteration < 10} {
    #     set color 0  ;# BLUE
    # } elseif {$iteration < 20} {
    #     set color 1  ;# GREEN
    # } else {
    #     set color 2  ;# RED
    #     set iteration 0
    # }
    
    puts "Iteration $iteration: Setting color..."
    set_line_color $color
    
    # Update every 2 seconds
    after 2000
}

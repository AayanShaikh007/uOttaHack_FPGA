# VIO Color Control - Same Laptop Setup

Change the waveform line color **programmatically** from a TCL script running on the **same Vivado laptop**.

## **Files:**

- `vivado_color_control.tcl` - TCL script (run on Vivado laptop)
- `video_uut_color.sv` - Modified Verilog module

## **Setup:**

### Step 1: Add to Vivado Project

1. Copy `video_uut_color.sv` to your Vivado project
2. Replace the old `video_uut` instantiation with `video_uut_color`

### Step 2: Update Module Instantiation

Replace in `fpga_top.sv`:
```verilog
video_uut_color video_uut_inst (
    .clk_i(clk_vid),
    .cen_i(1'b1),
    .rst_i(rst_vid),
    .vid_sel_i(probe_out0[0]),
    .vid_rgb_i(tpg_rgb),
    .vh_blank_i({tpg_v_blank, tpg_h_blank}),
    .dvh_sync_i({tpg_d_sync, tpg_v_sync, tpg_h_sync}),
    .vio_color_i(probe_out0[2:0]),  // 3-bit color from VIO
    .dvh_sync_o(vid_dvh_sync),
    .vid_rgb_o(vid_rgb)
);
```

### Step 3: Program FPGA

Generate bitstream and program the FPGA as usual.

## **Running the TCL Script:**

### **Option 1: From Vivado TCL Console (Recommended)**

1. Open Vivado with FPGA programmed
2. **TCL Console** → Bottom of screen
3. Paste:
```tcl
source C:/Coding/fpga_tcl/vivado_color_control.tcl
```
4. Colors change automatically every 2 seconds!

### **Option 2: Command Line**

```powershell
vivado -mode batch -source vivado_color_control.tcl -notrace
```

## **How It Works:**

```
TCL Script (Vivado laptop)
    ↓
compute_color() function
    ↓
set_line_color() sets VIO probe
    ↓
FPGA reads vio_color_i
    ↓
get_color_from_probe() converts to RGB
    ↓
Line displayed in new color
```

## **Color Mapping:**

- **0** → BLUE
- **1** → GREEN  
- **2** → RED

## **Customizing:**

Edit the `compute_color()` function in `vivado_color_control.tcl`:

```tcl
proc compute_color {} {
    # Your custom logic here
    
    # Example: Based on time
    set time [clock seconds]
    if {$time % 10 < 3} {
        return 0  ;# BLUE
    } elseif {$time % 10 < 6} {
        return 1  ;# GREEN
    } else {
        return 2  ;# RED
    }
}
```

Or add sensor readings, file input, etc.

## **Troubleshooting:**

**"ERROR: Could not set color"**
- Make sure hardware is connected in Vivado
- VIO probe must be named `vio_0/probe_out0`
- FPGA must be programmed with updated bitstream

**Color doesn't change**
- Check that `video_uut_color.sv` is in project
- Verify VIO probe width is at least 3 bits
- Regenerate bitstream after adding module

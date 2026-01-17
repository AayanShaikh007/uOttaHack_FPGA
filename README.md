# FPGA UART to HDMI Display Project

Display numbers from your PC on the FPGA's HDMI screen using UART communication.

## Hardware Setup

### Required Hardware:
1. **Xilinx Zynq UltraScale+ FPGA board**
2. **FTDI USB-to-UART adapter** (~$8)
3. **3x Jumper wires** (Female-to-Male)
4. **2x USB cables**
5. **HDMI monitor** connected to FPGA

### Wiring:

```
FTDI Adapter          Zynq Board
------------          ----------
TX   →      PL_GPIO01 (FPGA RX input)
RX   →      PL_GPIO02 (FPGA TX output)
GND    →      GND pin
```

### USB Connections:

```
PC #1 (Vivado)        →  FPGA JTAG Port  (programming)
PC #2 (TCL Script)    →  FTDI Adapter    (UART data)
```

## Files

### Verilog Files (for Laptop #1 - Programming):
- `uart_rx.sv` - UART receiver module
- `number_display.sv` - 7-segment style number display on screen
- `video_uut_uart.sv` - Modified video module with UART input

### TCL Script (for Laptop #2 - Control):
- `send_number.tcl` - Interactive script to send numbers to FPGA

## Usage

### Step 1: Program the FPGA (Laptop #1)

1. Open Vivado project at `..\uOttaHack_FPGA\fpga_top\fpga_top.xpr`
2. Copy these files to the project:
   - `uart_rx.sv`
   - `number_display.sv`
   - `video_uut_uart.sv`
3. Replace `video_uut` instantiation in `fpga_top.sv` with:

```verilog
video_uut_uart video_uut_inst (
    .clk_i          (clk_vid),
    .cen_i          (1'b1),
    .rst_i          (rst_vid),
    .vid_sel_i      (probe_out0[0]),
    .vid_rgb_i      (tpg_rgb),
    .vh_blank_i     ({tpg_v_blank, tpg_h_blank}),
    .dvh_sync_i     ({tpg_d_sync, tpg_v_sync, tpg_h_sync}),
    .uart_rx_i      (pin_pl_gpio_01),  // Add UART RX pin
    .dvh_sync_o     (vid_dvh_sync),
    .vid_rgb_o      (vid_rgb)
);
```

4. Add pin constraint in `.xdc` file:
```tcl
set_property PACKAGE_PIN [your_gpio01_pin] [get_ports pin_pl_gpio_01]
set_property IOSTANDARD LVCMOS33 [get_ports pin_pl_gpio_01]
```

5. Generate bitstream and program FPGA

### Step 2: Run TCL Script (Laptop #2)

1. Check COM port number:
   - Open **Device Manager** → Ports (COM & LPT)
   - Find "USB Serial Port (COMx)" - note the number

2. Edit `send_number.tcl`:
   ```tcl
   set COM_PORT "COM5"  # Change to your COM port
   ```

3. Run the script:
   ```powershell
   tclsh send_number.tcl
   ```

4. Type numbers (0-255) and watch them appear on the HDMI screen!

## Example Session

```
PS> tclsh send_number.tcl
Opening COM5 at 115200 baud...
Connected to FPGA!
Commands:
  Type a number (0-255) to display on screen
  Type 'quit' to exit

Number> 42
Sent: 42 (0x2A) - Check HDMI display!

Number> 123
Sent: 123 (0x7B) - Check HDMI display!

Number> 255
Sent: 255 (0xFF) - Check HDMI display!

Number> quit
Closing connection...
Disconnected from FPGA
```

## Display Format

Numbers are displayed as **3-digit decimal** (000-255) in yellow on the screen:
- 7-segment style digits
- Centered on 1080p screen
- Large, easy to read
- Background shows the original waveform animation

## Troubleshooting

### COM Port Not Found:
- Check Device Manager for correct port number
- Install FTDI drivers if needed
- Try different USB port

### No Display on Screen:
- Verify HDMI cable is connected
- Check UART wiring (TX→RX, RX→TX)
- Verify baud rate matches (115200)
- Check pin assignments in .xdc file

### FPGA Not Responding:
- Re-program the bitstream
- Check UART RX pin in constraints file
- Verify clock frequency in uart_rx.sv matches your design

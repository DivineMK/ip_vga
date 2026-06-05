# ip_vga

A free and open-source, fully synthesizable VGA text mode controller.

## Caveats

- Monochrome only — color attributes are not supported.
- Attribute bits for cursor rendering are not processed.
- Font size is fixed to 8x8 pixels.

## Authors

- Khanh Lo \<khanlo@student.ethz.ch\>

This project builds on PULP's [`axi_vga`](https://github.com/pulp-platform/axi_vga).

## Structure

| File | Description |
|---|---|
| `src/ip_vga.sv` | Top-level VGA controller |
| `src/ip_vga_config_pkg.sv` | Configuration parameters |
| `src/ip_vga_regs_pkg.sv` | Register layout definitions |
| `src/ip_vga_regs.sv` | Register file |
| `src/ip_vga_timing_fsm.sv` | VGA timing state machine |
| `src/ip_vga_fetcher.sv` | Data fetcher from memory |
| `src/font.sv` | Font ROM |
| `src/text_buffer.sv` | Text buffer management |

## Simulation

If you have Questa Advanced Simulator:

```
make vsim
```

## Licensing

This project is licensed under the Solderpad Hardware License, Version 0.51. See `LICENSE` for the full text.
SPDX-License-Identifier: SHL-0.51

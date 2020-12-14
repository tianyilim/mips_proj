// Top-level wrapper for the cache controller and the harvard CPU
`timescale 1ns / 1ns
module mips_cpu_bus(
    /* Standard signals */
    input logic clk,
    input logic reset,
    output logic active,
    output logic[31:0] register_v0,

    /* Avalon memory mapped bus controller (master) */
    output logic[31:0] address,
    output logic write,
    output logic read,
    input logic waitrequest,
    output logic[31:0] writedata,
    output logic[3:0] byteenable,
    input logic[31:0] readdata
);

    logic clk_enable_cpu_cc;
    logic[3:0] byte_en_cpu_cc;
    logic[31:0] instr_address_cpu_cc;
    logic[31:0] instr_readdata_cpu_cc;
    logic instr_read_cpu_cc;

    logic[31:0] data_address_cpu_cc;
    logic data_write_cpu_cc;
    logic data_read_cpu_cc;
    logic[31:0] data_writedata_cpu_cc;
    logic[31:0] data_readdata_cpu_cc;

    logic wb_empty;

    logic cpu_active;

    assign active = cpu_active || !wb_empty;


    mips_cpu_harvard cpu(.clk(clk), .rst(reset), .clk_enable(clk_enable_cpu_cc), .register_v0(register_v0),
                        .active(cpu_active), .byteenable(byte_en_cpu_cc),
                        .instr_address(instr_address_cpu_cc), .instr_readdata(instr_readdata_cpu_cc), .instr_read(instr_read_cpu_cc),
                        .data_address(data_address_cpu_cc), .data_write(data_write_cpu_cc), .data_read(data_read_cpu_cc),
                        .data_writedata(data_writedata_cpu_cc), .data_readdata(data_readdata_cpu_cc)
                        );

    mips_cache_controller cc(.clk(clk), .rst(reset), .clk_enable(clk_enable_cpu_cc),
                        .instr_address(instr_address_cpu_cc), .instr_readdata(instr_readdata_cpu_cc), .instr_read(instr_read_cpu_cc),
                        .data_address(data_address_cpu_cc), .data_write(data_write_cpu_cc), .data_read(data_read_cpu_cc),
                        .data_writedata(data_writedata_cpu_cc), .data_readdata(data_readdata_cpu_cc),
                        .data_byteenable(byte_en_cpu_cc),
                        .mem_address(address), .mem_write(write), .mem_read(read),
                        .mem_writedata(writedata), .mem_byteenable(byteenable), .mem_readdata(readdata),
                        .waitrequest(waitrequest),

                        .wb_empty_out(wb_empty)
                        );

endmodule

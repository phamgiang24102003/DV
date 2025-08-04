`timescale 1ns/1ns

module apb_protocol (
    input        PCLK,
    input        PRESETn,
    input        transfer,
    input        READ_WRITE,
    input  [8:0] apb_write_paddr,
    input  [7:0] apb_write_data,
    input  [8:0] apb_read_paddr,
    output       PSLVERR,
    output [7:0] apb_read_data_out
);

    wire [7:0] PWDATA, PRDATA, PRDATA1, PRDATA2;
    wire [8:0] PADDR;

    wire       PREADY, PREADY1, PREADY2;
    wire       PENABLE, PSEL1, PSEL2, PWRITE;

    assign PREADY = PADDR[8] ? PREADY2 : PREADY1;
    assign PRDATA = READ_WRITE ? (PADDR[8] ? PRDATA2 : PRDATA1) : 8'dx;

    master dut_mas (
        .apb_write_paddr     (apb_write_paddr),
        .apb_read_paddr      (apb_read_paddr),
        .apb_write_data      (apb_write_data),
        .PRDATA              (PRDATA),
        .PRESETn             (PRESETn),
        .PCLK                (PCLK),
        .READ_WRITE          (READ_WRITE),
        .transfer            (transfer),
        .PREADY              (PREADY),
        .PSEL1               (PSEL1),
        .PSEL2               (PSEL2),
        .PENABLE             (PENABLE),
        .PADDR               (PADDR),
        .PWRITE              (PWRITE),
        .PWDATA              (PWDATA),
        .apb_read_data_out   (apb_read_data_out),
        .PSLVERR             (PSLVERR)
    );

    slave1 dut1 (
        .PCLK      (PCLK),
        .PRESETn   (PRESETn),
        .PSEL      (PSEL1),
        .PENABLE   (PENABLE),
        .PWRITE    (PWRITE),
        .PADDR     (PADDR[7:0]),
        .PWDATA    (PWDATA),
        .PRDATA1   (PRDATA1),
        .PREADY    (PREADY1)
    );

    slave2 dut2 (
        .PCLK      (PCLK),
        .PRESETn   (PRESETn),
        .PSEL      (PSEL2),
        .PENABLE   (PENABLE),
        .PWRITE    (PWRITE),
        .PADDR     (PADDR[7:0]),
        .PWDATA    (PWDATA),
        .PRDATA2   (PRDATA2),
        .PREADY    (PREADY2)
    );

endmodule
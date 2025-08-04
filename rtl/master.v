`timescale 1ns/1ns

module master (
    input  [8:0] apb_write_paddr, apb_read_paddr,
    input  [7:0] apb_write_data, PRDATA,         
    input        PRESETn, PCLK, READ_WRITE, transfer, PREADY,
    output       PSEL1, PSEL2,
    output reg   PENABLE,
    output reg  [8:0] PADDR,
    output reg        PWRITE,
    output reg  [7:0] PWDATA, apb_read_data_out,
    output            PSLVERR
);

    reg [2:0] state, next_state;

    reg invalid_setup_error;
    reg setup_error;
    reg invalid_read_paddr;
    reg invalid_write_paddr;
    reg invalid_write_data;

    localparam IDLE   = 3'b001,
               SETUP  = 3'b010,
               ENABLE = 3'b100;

    // State register
    always @(posedge PCLK) begin
        if (!PRESETn)
            state <= IDLE;
        else
            state <= next_state; 
    end

    // State transition logic
    always @(state, transfer, PREADY) begin
        if (!PRESETn)
            next_state = IDLE;
        else begin
            PWRITE = ~READ_WRITE;
            case (state)
                IDLE: begin
                    PENABLE = 0;
                    if (!transfer)
                        next_state = IDLE;
                    else
                        next_state = SETUP;
                end

                SETUP: begin
                    PENABLE = 0;
                    if (READ_WRITE)
                        PADDR = apb_read_paddr;
                    else begin
                        PADDR  = apb_write_paddr;
                        PWDATA = apb_write_data;
                    end

                    if (transfer && !PSLVERR)
                        next_state = ENABLE;
                    else
                        next_state = IDLE;
                end

                ENABLE: begin
                    if (PSEL1 || PSEL2)
                        PENABLE = 1;

                    if (transfer && !PSLVERR) begin
                        if (PREADY) begin
                            if (!READ_WRITE)
                                next_state = SETUP;
                            else begin
                                next_state = SETUP;
                                apb_read_data_out = PRDATA;
                            end
                        end else
                            next_state = ENABLE;
                    end else
                        next_state = IDLE;
                end

                default: next_state = IDLE;
            endcase
        end
    end

    // PSEL logic
    assign {PSEL1, PSEL2} = ((state != IDLE) ? 
                              (PADDR[8] ? {1'b0, 1'b1} : {1'b1, 1'b0}) : 2'd0);

    // PSLVERR logic
    always @(*) begin
        if (!PRESETn) begin
            setup_error         = 0;
            invalid_read_paddr  = 0;
            invalid_write_paddr = 0;
            invalid_write_data  = 0;
        end else begin
            setup_error = (state == IDLE && next_state == ENABLE) ? 1 : 0;

            invalid_write_data = ((apb_write_data === 8'dx) && 
                                  (!READ_WRITE) &&
                                  (state == SETUP || state == ENABLE)) ? 1 : 0;

            invalid_read_paddr = ((apb_read_paddr === 9'dx) &&
                                  READ_WRITE &&
                                  (state == SETUP || state == ENABLE)) ? 1 : 0;

            invalid_write_paddr = ((apb_write_paddr === 9'dx) &&
                                   (!READ_WRITE) &&
                                   (state == SETUP || state == ENABLE)) ? 1 : 0;

            if (state == SETUP) begin
                if (PWRITE) begin
                    setup_error = (PADDR == apb_write_paddr && PWDATA == apb_write_data) ? 0 : 1;
                end else begin
                    setup_error = (PADDR == apb_read_paddr) ? 0 : 1;
                end
            end else begin
                setup_error = 0;
            end
        end

        invalid_setup_error = setup_error || 
                              invalid_read_paddr || 
                              invalid_write_data || 
                              invalid_write_paddr;
    end

    assign PSLVERR = invalid_setup_error;

endmodule
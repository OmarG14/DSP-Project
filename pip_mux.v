module pip_mux ( in, RST, clk,ce , out );
    parameter n = 18;
    parameter PIPLINING = 1;
    parameter RST_TYPE = "SYNC";

    input  [n-1:0] in;
    input  clk, RST , ce;
    output [n-1:0] out;

    reg  [n-1:0] out_reg1, out_reg2;
    wire [n-1:0] reg_out;

    generate

    if (RST_TYPE == "SYNC") begin : sync_gen
        always @(posedge clk) begin
            if (RST)
                out_reg1 <= 0;
            else if (ce)
                out_reg1 <= in;
        end
        assign reg_out = out_reg1;
    end

    else begin : async_gen
        always @(posedge clk or posedge RST) begin
            if (RST)
                out_reg2 <= 0;
            else if (ce)
                out_reg2 <= in;
        end
        assign reg_out = out_reg2;
    end

    endgenerate

    assign out = PIPLINING ? reg_out : in;

endmodule
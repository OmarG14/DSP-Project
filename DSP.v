module DSP (A, B, D, C, BCIN, CLK, CARRYIN, OPMODE, RSTA, RSTB, RSTM, RSTP, RSTC, RSTD, RSTCARRYIN, RSTOPMODE, CEA, CEB, CEM, CEP, CEC, CED, CECARRYIN, CEOPMODE, PCIN, BCOUT, PCOUT, P, M, CARRYOUT, CARRYOUTF) ;

parameter A0REG = 0,
          A1REG = 1,
          B0REG = 0,
          B1REG = 1,
          CREG = 1,
          DREG = 1,
          MREG = 1,
          PREG = 1,
          CARRYINREG = 1,
          CARRYOUTREG = 1,
          OPMODEREG = 1,
          B_INPUT = "DIRECT",
          CARRYINSEL = "OPMODE5",
          RSTTYPE = "SYNC" ;


input  [17:0] A , B , D , BCIN ;
input  [47:0] C , PCIN ;
input  [7:0] OPMODE ;
input  CLK, CARRYIN, RSTA, RSTB, RSTM, RSTP, RSTC, RSTD, RSTCARRYIN, RSTOPMODE, CEA, CEB, CEM, CEP, CEC, CED, CECARRYIN, CEOPMODE ;

output [17:0] BCOUT ;
output [47:0] PCOUT , P ;
output [35:0] M ;
output CARRYOUT , CARRYOUTF ;

wire cin , CYI ;
wire [17:0] A0_reg , B0_reg , B_in , D_reg , pre_addsub_out , B1 , B1_reg , A1_reg ;
wire [47:0] C_reg , Z_out , X_out ;
wire [48:0] Post_addsub_out ;
wire [35:0] multiplier_out ;
assign B_in = B_INPUT == "DIRECT" ? B : B_INPUT == "CASCADE" ? BCIN : 18'b0 ;

pip_mux  #( .n(18) , .PIPLINING(A0REG) , .RST_TYPE(RSTTYPE) )  A0_inst ( A , RSTA , CLK , CEA , A0_reg );
pip_mux  #( .n(18) , .PIPLINING(B0REG) , .RST_TYPE(RSTTYPE) )  B0_inst ( B_in , RSTB , CLK , CEB , B0_reg );
pip_mux  #( .n(18) , .PIPLINING(DREG)  , .RST_TYPE(RSTTYPE) )  D_inst ( D , RSTD , CLK , CED , D_reg );
pip_mux  #( .n(48) , .PIPLINING(CREG)  , .RST_TYPE(RSTTYPE) )  C_inst ( C , RSTC , CLK , CEC , C_reg );

assign pre_addsub_out = OPMODE[6] ? D_reg - B0_reg : D_reg + B0_reg ;
assign B1 = OPMODE[4] ? pre_addsub_out : B0_reg ;

pip_mux  #( .n(18) , .PIPLINING(B1REG) , .RST_TYPE(RSTTYPE) )  B1_inst ( B1 , RSTB , CLK , CEB , B1_reg );
assign BCOUT = B1_reg ;

pip_mux  #( .n(18) , .PIPLINING(A1REG) , .RST_TYPE(RSTTYPE) )  A1_inst ( A0_reg , RSTA , CLK , CEA , A1_reg );

assign multiplier_out = B1_reg * A1_reg ;

pip_mux  #( .n(36) , .PIPLINING(MREG) , .RST_TYPE(RSTTYPE) )  M_inst ( multiplier_out , RSTM , CLK , CEM , M );

assign cin = CARRYINSEL == "OPMODE5" ? OPMODE[5] : CARRYINSEL == "CARRYIN" ? CARRYIN : 1'b0 ;

pip_mux  #( .n(1) , .PIPLINING(CARRYINREG) , .RST_TYPE(RSTTYPE) )  CIN_inst ( cin , RSTCARRYIN , CLK , CECARRYIN , CYI );

assign Z_out = OPMODE[3] ? OPMODE[2] ? C_reg : P : OPMODE[2] ? PCIN : 48'b0 ;
assign X_out = OPMODE[1] ? OPMODE[0] ? {D[11:0], A, B} : P : OPMODE[0] ? {{12{1'b0}}, M} : 48'b0 ;

assign Post_addsub_out = OPMODE[7] ? ({1'b0, Z_out} - ({1'b0, X_out} + CYI) )
                                    : ({1'b0, Z_out} + {1'b0, X_out} + CYI);

pip_mux  #( .n(48) , .PIPLINING(PREG) , .RST_TYPE(RSTTYPE) )  P_inst ( Post_addsub_out[47:0] , RSTP , CLK , CEP , P );
assign PCOUT = P ;

pip_mux  #( .n(1) , .PIPLINING(CARRYOUTREG) , .RST_TYPE(RSTTYPE) )  CYO_inst ( Post_addsub_out[48] , RSTCARRYIN , CLK , CECARRYIN , CARRYOUT );

assign CARRYOUTF = CARRYOUT ;

endmodule
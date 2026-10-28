module DSP_tb ;

reg  [17:0] A , B , D , BCIN ;
reg  [47:0] C , PCIN;
reg  [7:0] OPMODE ;
reg  CLK, CARRYIN, RSTA, RSTB, RSTM, RSTP, RSTC, RSTD, RSTCARRYIN, RSTOPMODE, CEA, CEB, CEM, CEP, CEC, CED, CECARRYIN, CEOPMODE ;

wire [17:0] BCOUT ;
wire [47:0] PCOUT , P ;
wire [35:0] M ;
wire CARRYOUT , CARRYOUTF ;


DSP DUT (A, B, D, C, BCIN, CLK, CARRYIN, OPMODE, RSTA, RSTB, RSTM, RSTP, RSTC, RSTD, RSTCARRYIN, RSTOPMODE, CEA, CEB, CEM, CEP, CEC, CED, CECARRYIN, CEOPMODE, PCIN, BCOUT, PCOUT, P, M, CARRYOUT, CARRYOUTF) ;


initial begin
    CLK = 0;
    forever begin
        #5 CLK = ~CLK ;
    end
end


initial begin

    {RSTA, RSTB, RSTM, RSTP, RSTC, RSTD, RSTCARRYIN, RSTOPMODE} = 8'hFF;
    A = $random;
    B = $random;
    D = $random;
    C = $random;
    BCIN = $random;
    OPMODE = $random;
    CARRYIN = $random;
    PCIN = $random;
    CEA = $random;
    CEB = $random;
    CEM = $random;
    CEP = $random;
    CEC = $random;
    CED = $random;
    CECARRYIN = $random;
    CEOPMODE = $random;

    @(negedge CLK) ;
    if ( BCOUT || PCOUT || P || M || CARRYOUT || CARRYOUTF ) begin
        $display ("ERROR in RST") ;
        $stop ;
    end

    @(negedge CLK) ;
     {RSTA, RSTB, RSTM, RSTP, RSTC, RSTD, RSTCARRYIN, RSTOPMODE} = 8'h00;

    CEA = 1'b1;
    CEB = 1'b1;
    CEM = 1'b1;
    CEP = 1'b1;
    CEC = 1'b1;
    CED = 1'b1;
    CECARRYIN = 1'b1;
    CEOPMODE = 1'b1;


    OPMODE = 8'b11011101 ;
    A = 20 ; B = 10 ; C = 350 ; D = 25;
    BCIN = $random ; PCIN = $random ; CARRYIN = $random ;
    repeat (4) @(negedge CLK) ;

    if(BCOUT == 'hf && M == 'h12c && P == 'h32 && PCOUT == 'h32 && CARRYOUT == 'b0 && CARRYOUTF == 'b0)
        $display ("Path 1 succeded") ;
    else begin
        $display("ERROR in path 1 ") ;
        $stop ;
    end


    OPMODE = 8'b00010000;
    repeat(3) @(negedge CLK ) ;

    if(BCOUT == 'h23 && M == 'h2bc && P == 'b0 && PCOUT == 'b0 && CARRYOUT == 'b0 && CARRYOUTF == 'b0)
        $display ("Path 2 succeded") ;
    else begin
        $display("ERROR in path 2 ") ;
        $stop ;
    end


    OPMODE = 8'b00001010 ;
    repeat(3) @(negedge CLK ) ;

    if (BCOUT == 'ha &&  M == 'hc8 && P == 'b0 && PCOUT == 'b0 && CARRYOUT == 'b0 && CARRYOUTF == 'b0)
        $display ("Path 3 succeded") ;
    else begin
        $display("ERROR in path 3 ") ;
        $stop ;
    end


    OPMODE = 8'b10100111 ;
    A = 5 ; B = 6 ; C = 350 ; D = 25; PCIN = 3000 ;
    BCIN = $random  ; CARRYIN = $random ;
    repeat (3) @(negedge CLK) ;

    if(BCOUT == 'h6 && M == 'h1e && P == 'hfe6fffec0bb1 && PCOUT == 'hfe6fffec0bb1 && CARRYOUT == 1 && CARRYOUTF == 1)
        $display ("Path 4 succeded") ;
    else begin
        $display("ERROR in path 4 ") ;
        $stop ;
    end

end
endmodule
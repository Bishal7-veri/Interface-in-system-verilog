// In system verilog, interface is a powerful construct used to group related signals and communications method together for cleaner and more modular design verification code.

// An interface is like a bundle of signals. You define it once, and then you can use it in both RTL and testbench code.


module and4(input [3:0] a,
            input [3:0] b,
            output [3:0] y);
  
  assign y = a&b;
  
endmodule

interface and_if();
  
  logic [3:0] a;
  logic [3:0] b;
  logic [3:0] y;
  
endinterface

module tb;
  
  and_if vif();
  
  and4 dut (.a(vif.a), .b(vif.b), .y(vif.y));
  
  initial
    begin
      vif.a = 4'b1010;
      vif.b = 4'b1111;
      #10
      $display ("a : %0d, b : %0d, y : %0d", vif.a, vif.b, vif.y);
    end
  
endmodule

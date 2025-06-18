
// creating module add to get the sum

module add
  (
    input [3:0] a,b,
    output reg [4:0] sum,
    input clk
  );
  
  
  always@(posedge clk)
    begin
      sum <= a + b;
    end
   
   
endmodule


// making the interface 

interface add_if;
  logic [3:0] a;
  logic [3:0] b;
  logic [4:0] sum;
  logic clk;
  
  
 
  
endinterface
 
 
// creating the class driver 

class driver;
  
  // creating a virtual interface for the interface to access the data 
  
  virtual add_if aif;
  
  // task run 
  
  task run();
    forever begin
      @(posedge aif.clk);  
      aif.a <= 2;
      aif.b <= 3;
      $display("[DRV] , a : %0d, b : %0d, y : %0d", aif.a, aif.b, aif.sum);
    end
  endtask
  
  
endclass
 
 
 
module tb;
 
  // creating the object for the interface 
  // creating object for the driver
  
 add_if aiff();
 driver drv;
  
  // adding dut for the module
  
  add dut (.a(aiff.a), .b(aiff.b), .sum(aiff.sum), .clk(aiff.clk) );
 
 // initializing the clock 
  
  initial begin
    aiff.clk <= 0;
   
  end
  
   always #10 aiff.clk <= ~aiff.clk;
 
 
   initial begin
     // making object of the driver into a constructor to access all the operations access as new
     drv = new();
     
     // drv.aif = aiff means all the values of object aiff created inside the testbench is assigned to drv.aif
     drv.aif = aiff;
     
     // drv.run() 
     drv.run();
     
   end
  
  initial
    begin
      #100
      $finish();
    end
  
endmodule

module add (input [3:0] a,
            input [3:0] b,
            output reg [4:0] sum);
  
  assign sum = a+ b;
  
endmodule

interface add_if;
  
  logic [3:0] a;
  logic [3:0] b;
  logic [4:0] sum;
  
endinterface

class transaction;
  randc bit [3:0] a;
  randc bit [3:0] b;
  bit [4:0] sum;

  function transaction copy();
    transaction t = new();
    t.a = this.a;
    t.b = this.b;
    t.sum = this.sum;
    return t;
  endfunction
endclass


class generator;

  transaction tr;
  mailbox #(transaction) mbx;
  event done;

  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
    tr = new();
  endfunction

  task run();
    for (int i = 0; i < 10; i++) begin
      assert(tr.randomize()) else $fatal("Randomization failed!");
      tr.sum = tr.a + tr.b; // Expected result
      $display("GEN : a = %0d , b = %0d , sum = %0d", tr.a, tr.b, tr.sum);
      mbx.put(tr.copy()); // Send to driver
      #5;
    end
    -> done; // Signal completion
  endtask

endclass


class driver;

  virtual add_if aif;
  transaction tr1;
  mailbox #(transaction) mbx;
  mailbox #(transaction) drv2scb;

  function new(mailbox #(transaction) mbx, mailbox #(transaction) drv2scb);
    this.mbx = mbx;
    this.drv2scb = drv2scb;
  endfunction

  task run();
    forever begin
      mbx.get(tr1);
      aif.a <= tr1.a;
      aif.b <= tr1.b;
      drv2scb.put(tr1.copy()); // Send expected data to scoreboard
      $display("DRV : a = %0d , b = %0d", tr1.a, tr1.b);
      #5;
    end
  endtask

endclass


class monitor;

  virtual add_if aif;
  mailbox #(transaction) mon2scb;

  function new(mailbox #(transaction) mon2scb);
    this.mon2scb = mon2scb;
  endfunction

  task run();
    transaction tr;
    forever begin
      #1; // Wait for DUT output
      tr = new();
      tr.a = aif.a;
      tr.b = aif.b;
      tr.sum = aif.sum;
      $display("MON : a = %0d , b = %0d , sum = %0d", tr.a, tr.b, tr.sum);
      mon2scb.put(tr);
      #5;
    end
  endtask

endclass


class scoreboard;

  mailbox #(transaction) drv2scb;
  mailbox #(transaction) mon2scb;

  function new(mailbox #(transaction) drv2scb, mailbox #(transaction) mon2scb);
    this.drv2scb = drv2scb;
    this.mon2scb = mon2scb;
  endfunction

  task run();
    transaction expected, actual;
    forever begin
      drv2scb.get(expected);
      mon2scb.get(actual);

      if ((expected.a === actual.a) &&
          (expected.b === actual.b) &&
          (expected.sum === actual.sum)) begin
        $display(" DATA MATCHED : a = %0d , b = %0d , sum = %0d", actual.a, actual.b, actual.sum);
      end else begin
        $error("MISMATCH: Expected a=%0d, b=%0d, sum=%0d | Got a=%0d, b=%0d, sum=%0d",
               expected.a, expected.b, expected.sum,
               actual.a, actual.b, actual.sum);
      end
    end
  endtask

endclass


module tb;

  generator g;
  driver drv;
  monitor mon;
  scoreboard sb;

  mailbox #(transaction) mbx;
  mailbox #(transaction) drv2scb;
  mailbox #(transaction) mon2scb;

  event done;

  add_if aiff();

  add dut (.a(aiff.a), .b(aiff.b), .sum(aiff.sum));

  initial begin
    mbx      = new();
    drv2scb  = new();
    mon2scb  = new();

    g   = new(mbx);
    drv = new(mbx, drv2scb);
    mon = new(mon2scb);
    sb  = new(drv2scb, mon2scb);

    drv.aif = aiff;
    mon.aif = aiff;

    done = g.done;
  end

  initial begin
    fork
      g.run();
      drv.run();
      mon.run();
      sb.run();
    join_none

    wait(done.triggered);
    #100 $finish;
  end

endmodule

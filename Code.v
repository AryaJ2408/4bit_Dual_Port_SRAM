module DualPortRAM (
    input clk,                   // Clock signal
    input [3:0] addr1,           // Address for Port 1
    input [3:0] addr2,           // Address for Port 2
    input [3:0] data_in1,        // Data input for Port 1
    input [3:0] data_in2,        // Data input for Port 2
    input we1,                   // Write enable for Port 1
    input we2,                   // Write enable for Port 2
    input re1,                   // Read enable for Port 1
    input re2,                   // Read enable for Port 2
    output reg [3:0] data_out1,  // Data output for Port 1
    output reg [3:0] data_out2,  // Data output for Port 2
    output [3:0] ram_out_0,      // RAM content at address 0
    output [3:0] ram_out_1       // RAM content at address 1
);

    // Declare a 16x4 RAM (16 locations, 4 bits each)
    reg [3:0] ram [15:0];

    // Port 1: Write or Read
    always @(posedge clk) begin
        if (we1 && !(we2 && (addr1 == addr2))) begin
            ram[addr1] <= data_in1;   // Write data to RAM at addr1, if Port 2 is not writing to the same address
        end
        if (re1) data_out1 <= ram[addr1];  // Read data from RAM at addr1
    end

    // Port 2: Write or Read
    always @(posedge clk) begin
        if (we2 && !(we1 && (addr1 == addr2))) begin
            ram[addr2] <= data_in2;   // Write data to RAM at addr2, if Port 1 is not writing to the same address
        end
        if (re2) data_out2 <= ram[addr2];  // Read data from RAM at addr2
    end

    // Both Ports: Prioritize Port 1 when both are writing to the same address
    always @(posedge clk) begin
        if (we1 && we2 && (addr1 == addr2)) begin
            ram[addr1] <= data_in1;  // Prioritize Port 1's data when both are writing to the same address
        end
    end
    assign ram_out_0 = ram[0];
    assign ram_out_1 = ram[1];
endmodule

module DualPortRAM_tb;

    // Testbench Signals
    reg clk;
    reg [3:0] addr1, addr2;
    reg [3:0] data_in1, data_in2;
    reg we1, we2, re1, re2;
    wire [3:0] data_out1, data_out2;
    wire [3:0] ram_out_0, ram_out_1;

    // Instantiate the DualPortRAM module
    DualPortRAM uut (
        .clk(clk),
        .addr1(addr1),
        .addr2(addr2),
        .data_in1(data_in1),
        .data_in2(data_in2),
        .we1(we1),
        .we2(we2),
        .re1(re1),
        .re2(re2),
        .data_out1(data_out1),
        .data_out2(data_out2),
        .ram_out_0(ram_out_0),
        .ram_out_1(ram_out_1)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Clock period = 10 time units
    end

    // Test Sequence
    initial begin
        // Initialize Inputs
        addr1 = 0; addr2 = 0;
        data_in1 = 4'b0000; data_in2 = 4'b0000;
        we1 = 0; we2 = 0;
        re1 = 0; re2 = 0;

        // Write to address 0 using Port 1
        #10;
        addr1 = 4'd0;
        data_in1 = 4'b1010;
        we1 = 1; // Write enable for Port 1

        // Wait for write to complete
        #10;
        we1 = 0; // Disable write enable for Port 1

        // Read from address 0 using Port 1
        #10;
        re1 = 1; // Read enable for Port 1

        // Write to address 1 using Port 2
        #10;
        addr2 = 4'd1;
        data_in2 = 4'b1100;
        we2 = 1; // Write enable for Port 2

        // Wait for write to complete
        #10;
        we2 = 0; // Disable write enable for Port 2

        // Read from address 1 using Port 2
        #10;
        re2 = 1; // Read enable for Port 2

        // Both Ports writing to the same address (Port 1 should take priority)
        #10;
        addr1 = 4'd0; addr2 = 4'd0; // Same address
        data_in1 = 4'b1111; data_in2 = 4'b1011; // Different data for each port
        we1 = 1; we2 = 1; // Write enable for both Ports

        // Wait for write to complete
        #10;
        we1 = 0; we2 = 0; // Disable write enables

        // Read from address 0 using Port 1
        #10;
        re1 = 1; // Read enable for Port 1

        // End simulation
        #20;
        $finish;
    end
endmodule

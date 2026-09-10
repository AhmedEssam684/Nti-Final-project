module ALU_unit(
    input [31:0] A, B, 
    input [3:0] Control_in,
    output reg zero,
    output reg [31:0] ALU_Result
);
    always @(*) begin
        case(Control_in)
            4'b0000: ALU_Result = A & B;                                   // AND
            4'b0001: ALU_Result = A | B;                                   // OR
            4'b0010: ALU_Result = A + B;                                   // ADD
            4'b0011: ALU_Result = A ^ B;                                   // XOR
            4'b0100: ALU_Result = A << B[4:0];                             // SLL
            4'b0101: ALU_Result = A >> B[4:0];                             // SRL
            4'b0110: ALU_Result = A - B;                                   // SUB
            4'b0111: ALU_Result = $signed(A) >>> B[4:0];                   // SRA
            4'b1000: ALU_Result = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0; // SLT
            4'b1001: ALU_Result = (A < B) ? 32'd1 : 32'd0;                 // SLTU
            4'b1010: ALU_Result = ~(A | B);                                // NOR
            default: ALU_Result = 32'b0;
        endcase
        zero = (ALU_Result == 32'b0) ? 1'b1 : 1'b0;
    end
endmodule

module ALU_Control( 
    input fun7, 
    input [1:0] ALUOp, 
    input [2:0] fun3,
    output reg [3:0] Control_out
);
    always @(*) begin
        case (ALUOp)
            2'b00: Control_out = 4'b0010; // ADD
            2'b01: Control_out = 4'b0110; // SUB
            2'b10, 2'b11: begin
                case (fun3)
                    3'b000: begin
                        if (ALUOp == 2'b10 && fun7 == 1'b1)
                            Control_out = 4'b0110; // SUB
                        else
                            Control_out = 4'b0010; // ADD / ADDI
                    end
                    3'b001: Control_out = 4'b0100; // SLL
                    3'b010: Control_out = 4'b1000; // SLT
                    3'b011: Control_out = 4'b1001; // SLTU
                    3'b100: Control_out = 4'b0011; // XOR
                    3'b101: begin
                        if (fun7 == 1'b1)
                            Control_out = 4'b0111; // SRA
                        else
                            Control_out = 4'b0101; // SRL
                    end
                    3'b110: Control_out = 4'b0001; // OR
                    3'b111: Control_out = 4'b0000; // AND
                    default: Control_out = 4'b0000;
                endcase
            end
            default: Control_out = 4'b0000;
        endcase
    end
endmodule

module Control_Unit(
    input [6:0] instruction,
    output reg Branch, MemRead, MemToReg, MemWrite, ALUSrc, RegWrite, 
    output reg [1:0] ALUOp
);
    always @(*) begin
        case(instruction)
            7'b0110011 : {ALUSrc, MemToReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} = 8'b001000_10; // R-type
            7'b0000011 : {ALUSrc, MemToReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} = 8'b111100_00; // I-type (load)
            7'b0010011 : {ALUSrc, MemToReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} = 8'b101000_10; // I-type (ALU)
            7'b0100011 : {ALUSrc, MemToReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} = 8'b100010_00; // S-type
            7'b1100011 : {ALUSrc, MemToReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} = 8'b000001_01; // B-type
            7'b0110111 : {ALUSrc, MemToReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} = 8'b101000_11; // U-type
            7'b1101111 : {ALUSrc, MemToReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} = 8'b101001_11; // J-type
            default    : {ALUSrc, MemToReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} = 8'b000000_00;
        endcase
    end
endmodule

module Data_Memory(
    input clk, rst, MemWrite, MemRead, 
    input [31:0] read_address, Write_data, 
    output [31:0] MemData_out
);
    integer k;
    reg [31:0] D_Memory[0:31];
    wire [4:0] word_addr = read_address[6:2];

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            for(k=0; k<32; k=k+1) begin
                D_Memory[k] <= 32'b0;
            end
        end
        else if(MemWrite) begin
            D_Memory[word_addr] <= Write_data;
        end
    end
    assign MemData_out = (MemRead) ? D_Memory[word_addr] : 32'b0;
endmodule

module ImmGen(
    input [6:0] Opcode,
    input [31:0] instruction,
    output reg [31:0] ImmExt
);
    always @(*) begin
        case(Opcode)
            7'b0000011, 7'b0010011 : ImmExt = {{20{instruction[31]}}, instruction[31:20]};
            7'b0100011             : ImmExt = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            7'b1100011             : ImmExt = {{19{instruction[31]}}, instruction[31], instruction[30:25], instruction[11:8], 1'b0};
            7'b0110111, 7'b0010111 : ImmExt = {instruction[31:12], 12'b0};
            7'b1101111             : ImmExt = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
            default                : ImmExt = 32'b0;
        endcase
    end
endmodule

module I_mem(
    input clk, rst,
    input [31:0] address,
    output reg [31:0] instruction
);
    reg [31:0] imem [0:31];
    integer k;
    wire [4:0] word_addr = address[6:2];

    initial begin
        for (k = 0; k < 32; k = k + 1) begin
            imem[k] = 32'b0;
        end
        // Test Program:
        imem[0] = 32'h00500093; // addi x1, x0, 5     (x1 = 5)
        imem[1] = 32'h00a00113; // addi x2, x0, 10    (x2 = 10)
        imem[2] = 32'h002081b3; // add  x3, x1, x2    (x3 = 15)
        imem[3] = 32'h00312023; // sw   x3, 0(x2)     (Mem[10] = 15)
        imem[4] = 32'h00012203; // lw   x4, 0(x2)     (x4 = 15)
    end

    always @(*) begin 
        if (rst) begin
            instruction = 32'b0;
        end else begin
            instruction = imem[word_addr];
        end 
    end
endmodule 

module Mux1(input sel1, input [31:0] A1, B1, output [31:0] Mux1_out);
    assign Mux1_out = (sel1==1'b0) ? A1 : B1;
endmodule

module AND_logic(input branch, zero, output and_out);
    assign and_out = branch & zero;
endmodule

module Adder(input [31:0] in_1, in_2, output [31:0] Sum_out);
    assign Sum_out = in_1 + in_2;
endmodule

module Reg_File(
    input clk, rst, RegWrite,
    input [4:0] Rs1, Rs2, Rd,
    input [31:0] Write_data,
    output [31:0] read_data1, read_data2
);
    integer k;
    reg [31:0] Registers[0:31];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (k = 0; k < 32; k = k + 1) begin
                Registers[k] <= 32'b0;
            end
        end
        else if (RegWrite && (Rd != 5'b0)) begin // Protect x0 from being written
            Registers[Rd] <= Write_data;
        end
    end

    assign read_data1 = (Rs1 == 0) ? 32'b0 : Registers[Rs1];
    assign read_data2 = (Rs2 == 0) ? 32'b0 : Registers[Rs2];

endmodule

module RISCV_Top(
    input clk,
    input rst
);
    wire [31:0] pc_current;
    wire [31:0] pc_next;
    wire [31:0] pc_plus_4;
    wire [31:0] branch_target;
    wire [31:0] instruction;
    wire Branch, MemRead, MemToReg, MemWrite, ALUSrc, RegWrite;
    wire [1:0] ALUOp;
    wire [3:0] alu_control_out;
    wire zero_flag;
    wire pc_sel;
    wire [31:0] reg_read_data_1;
    wire [31:0] reg_read_data_2;
    wire [31:0] write_back_data;
    wire [31:0] imm_ext;
    wire [31:0] alu_operand_b;
    wire [31:0] alu_result;
    wire [31:0] mem_read_data;
    reg [31:0] PC;

    always @(posedge clk or posedge rst) begin
        if (rst)
            PC <= 32'b0;
        else
            PC <= pc_next;
    end

    assign pc_current = PC;

    Adder PC_Adder (
        .in_1(pc_current),
        .in_2(32'd4),
        .Sum_out(pc_plus_4)
    );

    I_mem Instruction_Mem (
        .clk(clk),
        .rst(rst),
        .address(pc_current),
        .instruction(instruction)
    );

    Control_Unit Main_Control (
        .instruction(instruction[6:0]),
        .Branch(Branch),
        .MemRead(MemRead),
        .MemToReg(MemToReg),
        .ALUOp(ALUOp),
        .MemWrite(MemWrite),
        .ALUSrc(ALUSrc),
        .RegWrite(RegWrite)
    );

    Reg_File Register_File (
        .clk(clk),
        .rst(rst),
        .RegWrite(RegWrite),
        .Rs1(instruction[19:15]),
        .Rs2(instruction[24:20]),
        .Rd(instruction[11:7]),
        .Write_data(write_back_data),
        .read_data1(reg_read_data_1),
        .read_data2(reg_read_data_2)
    );

    ImmGen Immediate_Generator (
        .Opcode(instruction[6:0]),
        .instruction(instruction),
        .ImmExt(imm_ext)
    );

    Mux1 ALU_Src_Mux (
        .sel1(ALUSrc),
        .A1(reg_read_data_2),
        .B1(imm_ext),
        .Mux1_out(alu_operand_b)
    );

    ALU_Control ALU_Control_Unit (
        .ALUOp(ALUOp),
        .fun7(instruction[30]),
        .fun3(instruction[14:12]),
        .Control_out(alu_control_out)
    );

    ALU_unit Main_ALU (
        .A(reg_read_data_1),
        .B(alu_operand_b),
        .Control_in(alu_control_out),
        .ALU_Result(alu_result),
        .zero(zero_flag)
    );

    Adder Branch_Adder (
        .in_1(pc_current),
        .in_2(imm_ext),
        .Sum_out(branch_target)
    );

    AND_logic Branch_AND (
        .branch(Branch),
        .zero(zero_flag),
        .and_out(pc_sel)
    );

    Mux1 PC_Mux (
        .sel1(pc_sel),
        .A1(pc_plus_4),
        .B1(branch_target),
        .Mux1_out(pc_next)
    );

    Data_Memory Data_Mem (
        .clk(clk),
        .rst(rst),
        .MemWrite(MemWrite),
        .MemRead(MemRead),
        .read_address(alu_result),
        .Write_data(reg_read_data_2),
        .MemData_out(mem_read_data)
    );

    Mux1 Writeback_Mux (
        .sel1(MemToReg),
        .A1(alu_result),
        .B1(mem_read_data),
        .Mux1_out(write_back_data)
    );

endmodule

// Dynamic, Self-Checking Testbench
module tb_top;
    reg clk;
    reg rst;

    RISCV_Top uut(
        .clk(clk), 
        .rst(rst)
    );

    // Clock Generation: 10ns period
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;

        // Apply Reset
        #20;
        rst = 0;

        // Run processor for 10 clock cycles (100ns)
        #100;

        // Display Simulation Results
        $display("----------------------------------------");
        $display("Execution Finished. Register Dump:");
        $display("x1 = %d (Expected: 5)",  uut.Register_File.Registers[1]);
        $display("x2 = %d (Expected: 10)", uut.Register_File.Registers[2]);
        $display("x3 = %d (Expected: 15)", uut.Register_File.Registers[3]);
        $display("x4 = %d (Expected: 15)", uut.Register_File.Registers[4]);
        $display("----------------------------------------");

        // Self-Checking Assertions
        if (uut.Register_File.Registers[1] === 32'd5  &&
            uut.Register_File.Registers[2] === 32'd10 &&
            uut.Register_File.Registers[3] === 32'd15 &&
            uut.Register_File.Registers[4] === 32'd15) begin
            $display(">> SUCCESS: ALL TESTBENCH CHECKS PASSED!");
        end else begin
            $display(">> ERROR: TESTBENCH VERIFICATION FAILED!");
        end

        $stop;
    end
endmodule
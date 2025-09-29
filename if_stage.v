module ifstage (
    input  wire        clk,
    input  wire        rst,
    // pipeline control signal, after '_' is the property of the front
    input  wire        other_validout,
    input  wire        id_allowin,
    output wire        if_allowin,  // means data can in, signal is foreahead
    output wire        if_validout,
    // pipeline data signal in, for branch or jump, contains addr_sel and PC
    input  wire [33:0] br_bus,
    // pipeline data signal out, to id stage, contains pc and inst
    output wire [63:0] if_to_id_bus,
    // inst sram interface
    output wire        inst_sram_en,
    output wire [ 3:0] inst_sram_we,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input  wire [31:0] inst_sram_rdata
);

// stage if, double hands
reg         valid;      // means data is valid, [IMPORTANT!]
wire        readygo;    // means task has done
wire [31:0] seq_pc;
wire [31:0] nextpc;
wire        br_taken;
wire        br_taken_cancel;
wire [31:0] br_target;
wire [31:0] inst;
reg  [31:0] pc;
reg  [33:0] br_bus_r;

assign readygo      = 1'b1;  // for that there's no adventure and wizard, we can send data at anytime
assign if_allowin   = ~valid | (readygo & id_allowin);
assign if_validout  = valid & readygo; // data is valid and can send to next stage
assign if_to_id_bus = {pc, inst};

// data valid
always @(posedge clk) begin
    if (rst) begin
        valid <= 1'b0;
    end
    else if (if_allowin) begin
        valid <= other_validout;
    end
    else if (br_taken_cancel) begin 
        valid <= 1'b0; // Flush Release
    end
end
always @(posedge clk) begin
    if (rst) begin
        br_bus_r <= 34'd0;
    end
    else if (other_validout & if_allowin) begin
        br_bus_r <= br_bus;
    end
end

assign {br_taken, br_taken_cancel, br_target} = br_bus_r;
assign seq_pc                                 = pc + 3'h4;
assign nextpc                                 = br_taken ? br_target : seq_pc;

always @(posedge clk) begin
    if (rst) begin
        pc <= 32'h1bfffffc;     //trick: to make nextpc be 0x1c000000 during reset, reason is loongarch's feature
    end
    else begin
        pc <= nextpc;
    end
end

assign inst_sram_en    = other_validout & if_allowin;
assign inst_sram_we    = 4'h0;
assign inst_sram_addr  = nextpc;
assign inst_sram_wdata = 32'b0;
assign inst            = inst_sram_rdata;

endmodule
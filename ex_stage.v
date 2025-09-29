module exstage (
    input  wire        clk,
    input  wire        rst,
    // pipeline control signal, after '_' is the property of the front
    input  wire        id_validout,
    input  wire        ma_allowin,
    output wire        ex_allowin,  // means data can in, signal is foreahead
    output wire        ex_validout,
    // pipeline data signal in, with control signals from id
    input  wire [150:0] id_to_ex_bus,
    // pipeline data signal out
    output wire [70:0] ex_to_ma_bus,
    output wire [ 4:0] ex_to_id_dest,
    // data sram interface
    output wire        data_sram_en,
    output wire [ 3:0] data_sram_we,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata
);

// stage ex, double hands
reg          valid;      // means data is valid, [IMPORTANT!]
wire         readygo;    // means task has done
reg  [150:0] id_to_ex_bus_r;
wire         ex_to_id_is_load;

wire [31:0] pc;
wire [11:0] alu_op;
wire        load_op;
wire        src1_is_pc;
wire        src2_is_imm;
wire        res_from_mem;
wire        gr_we;
wire        mem_we;
wire [ 4:0] dest;
wire [31:0] rj_value;
wire [31:0] rkd_value;
wire [31:0] imm;

wire [31:0] alu_src1   ;
wire [31:0] alu_src2   ;
wire [31:0] alu_result ;

assign {alu_op       ,    // 12
        load_op      ,    // 1
        src1_is_pc   ,    // 1
        src2_is_imm  ,    // 1
        gr_we        ,    // 1
        mem_we       ,    // 1
        dest         ,    // 5
        imm          ,    // 32
        rj_value     ,    // 32
        rkd_value    ,    // 32
        pc           ,    // 32
        res_from_mem} = id_to_ex_bus_r;    /// totally is 151

assign ex_to_ma_bus = {res_from_mem,    //70:70 1
                       gr_we       ,    //69:69 1
                       dest        ,    //68:64 5
                       alu_result  ,    //63:32 32
                       pc               //31:0  32
                      };                /// totally is 71
assign ex_to_id_dest = dest & {5{valid}};

assign readygo      = 1'b1;  // for that there's no adventure and wizard, we can send data at anytime
assign ex_allowin   = ~valid | (readygo & ma_allowin);
assign ex_validout  = valid & readygo; // data is valid and can send to next stage

// data & its valid
always @(posedge clk) begin
    if (rst) begin
        valid <= 1'b0;
    end
    else if (ex_allowin) begin
        valid <= id_validout;
    end
end
always @(posedge clk) begin
    if (rst) begin
        id_to_ex_bus_r <= 151'b0;
    end
    else if (id_validout & ex_allowin) begin
        id_to_ex_bus_r <= id_to_ex_bus;
    end
end

assign alu_src1 = src1_is_pc  ? pc[31:0] : rj_value;
assign alu_src2 = src2_is_imm ? imm : rkd_value;

alu u_alu(
    .alu_op     (alu_op    ),
    .alu_src1   (alu_src1  ),
    .alu_src2   (alu_src2  ),
    .alu_result (alu_result)
    );

assign data_sram_en    = 1'b1;
assign data_sram_we    = mem_we && valid ? 4'hf : 4'h0;
assign data_sram_addr  = alu_result;
assign data_sram_wdata = rkd_value;

endmodule
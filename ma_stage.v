module mastage (
    input  wire        clk,
    input  wire        rst,
    // pipeline control signal, after '_' is the property of the front
    input  wire        ex_validout,
    input  wire        wb_allowin,
    output wire        ma_allowin,  // means data can in, signal is foreahead
    output wire        ma_validout,
    // pipeline data signal in, with control signals from id
    input  wire [70:0] ex_to_ma_bus,
    // pipeline data signal out
    output wire [69:0] ma_to_wb_bus,
    output wire [ 4:0] ma_to_id_dest,
    // data sram interface
    input  wire [31:0] data_sram_rdata
);

// stage ma, double hands
reg         valid;      // means data is valid, [IMPORTANT!]
wire        readygo;    // means task has done
reg  [70:0] ex_to_ma_bus_r;

wire        res_from_mem;
wire        gr_we;
wire [31:0] pc;
wire [ 4:0] dest;
wire [31:0] alu_result;
wire [31:0] mem_result;
wire [31:0] final_result;

assign mem_result   = data_sram_rdata;
assign final_result = res_from_mem ? mem_result : alu_result;

assign {res_from_mem,  //70:70
        gr_we       ,  //69:69
        dest        ,  //68:64
        alu_result  ,  //63:32
        pc             //31:0
       } = ex_to_ma_bus_r;

assign ma_to_wb_bus = {gr_we       ,    //69:69
                       dest        ,    //68:64
                       final_result,    //63:32
                       pc               //31:0
                       };   /// totally 70
assign ma_to_id_dest = dest & {5{valid}};

assign readygo      = 1'b1;  // for that there's no adventure and wizard, we can send data at anytime
assign ma_allowin   = ~valid | (readygo & wb_allowin);
assign ma_validout  = valid & readygo; // data is valid and can send to next stage

// data & its valid
always @(posedge clk) begin
    if (rst) begin
        valid <= 1'b0;
    end
    else if (ma_allowin) begin
        valid <= ex_validout;
    end
end
always @(posedge clk) begin
    if (rst) begin
        ex_to_ma_bus_r <= 71'b0;
    end
    else if (ex_validout & ma_allowin) begin
        ex_to_ma_bus_r <= ex_to_ma_bus;
    end
end

endmodule
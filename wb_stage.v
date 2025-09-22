module wbstage (
    input  wire        clk,
    input  wire        rst,
    // pipeline control signal, after '_' is the property of the front
    input  wire        ma_validout,
    input  wire        other_allowin,
    output wire        wb_allowin,  // means data can in, signal is foreahead
    output wire        wb_validout,
    // pipeline data signal in, with control signals from id
    input  wire [69:0] ma_to_wb_bus,
    // pipeline data signal out
    output wire [37:0] wb_regfile_bus,
    // trace debug interface
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);

// stage wb, double hands
reg         valid;      // means data is valid, [IMPORTANT!]
wire        readygo;    // means task has done
reg  [69:0] ma_to_wb_bus_r;

wire        gr_we;
wire        rf_we;
wire [ 4:0] rf_waddr;
wire [ 4:0] dest;
wire [31:0] pc;
wire [31:0] rf_wdata;
wire [31:0] final_result;

assign {gr_we       ,    //69:69
        dest        ,    //68:64
        final_result,    //63:32
        pc               //31:0
        } = ma_to_wb_bus_r;

assign rf_we    = gr_we & valid;
assign rf_waddr = dest;
assign rf_wdata = final_result;

assign ws_to_rf_bus = {rf_we   ,    //37:37
                       rf_waddr,    //36:32
                       rf_wdata     //31:0
                      };        /// totally 38

// debug info generate
assign debug_wb_pc       = pc;
assign debug_wb_rf_we    = {4{rf_we}};
assign debug_wb_rf_wnum  = dest;
assign debug_wb_rf_wdata = final_result;

assign readygo      = 1'b1;  // for that there's no adventure and wizard, we can send data at anytime
assign wb_allowin   = ~valid | (readygo & other_allowin);
assign wb_validout  = valid & readygo; // data is valid and can send to next stage

// data & its valid
always @(posedge clk) begin
    if (rst) begin
        valid <= 1'b0;
    end
    else if (wb_allowin) begin
        valid <= ma_validout;
    end
end
always @(posedge clk) begin
    if (rst) begin
        ma_to_wb_bus_r <= 70'b0;
    end
    else if (ma_validout & wb_allowin) begin
        ma_to_wb_bus_r <= ma_to_wb_bus;
    end
end

endmodule
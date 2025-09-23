module mycpu_top(
    input  wire        clk,
    input  wire        resetn,
    // inst sram interface
    output wire        inst_sram_en,
    output wire [ 3:0] inst_sram_we,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input  wire [31:0] inst_sram_rdata,
    // data sram interface
    output wire        data_sram_en,
    output wire [ 3:0] data_sram_we,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    input  wire [31:0] data_sram_rdata,
    // trace debug interface
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);
reg         reset;
always @(posedge clk) reset <= ~resetn;

wire         if_allowin;
wire         id_allowin;
wire         ex_allowin;
wire         ma_allowin;
wire         wb_allowin;
wire         other_allowin;
wire         other_validout;
wire         if_validout;
wire         id_validout;
wire         ex_validout;
wire         ma_validout;
wire         wb_validout;

wire [ 63:0] if_to_id_bus;
wire [150:0] id_to_ex_bus;
wire [ 70:0] ex_to_ma_bus;
wire [ 69:0] ma_to_wb_bus;
wire [ 37:0] wb_regfile_bus;
wire [ 32:0] br_bus;

assign other_allowin  = 1'b1;
assign other_validout = 1'b1;

ifstage if_stage(
    .clk            (clk            ),
    .rst            (reset          ),
    .other_validout (other_validout ),
    .id_allowin     (id_allowin     ),
    .if_allowin     (if_allowin     ),
    .if_validout    (if_validout    ),
    .br_bus         (br_bus         ),
    .if_to_id_bus   (if_to_id_bus   ),
    .inst_sram_en   (inst_sram_en   ),
    .inst_sram_we   (inst_sram_we   ),
    .inst_sram_addr (inst_sram_addr ),
    .inst_sram_wdata(inst_sram_wdata),
    .inst_sram_rdata(inst_sram_rdata)
);
idstage id_stage(
    .clk            (clk            ),
    .rst            (reset          ),
    .if_validout    (if_validout    ),
    .ex_allowin     (ex_allowin     ),
    .id_allowin     (id_allowin     ),
    .id_validout    (id_validout    ),
    .if_to_id_bus   (if_to_id_bus   ),
    .wb_regfile_bus (wb_regfile_bus ),
    .br_bus         (br_bus         ),
    .id_to_ex_bus   (id_to_ex_bus   )
);
exstage ex_stage(
    .clk            (clk            ),
    .rst            (reset          ),
    .id_validout    (id_validout    ),
    .ma_allowin     (ma_allowin     ),
    .ex_allowin     (ex_allowin     ),
    .ex_validout    (ex_validout    ),
    .id_to_ex_bus   (id_to_ex_bus   ),
    .ex_to_ma_bus   (ex_to_ma_bus   ),
    .data_sram_en   (data_sram_en   ),
    .data_sram_we   (data_sram_we   ),
    .data_sram_addr (data_sram_addr ),
    .data_sram_wdata(data_sram_wdata)
);
mastage ma_stage(
    .clk            (clk            ),
    .rst            (reset          ),
    .ex_validout    (ex_validout    ),
    .wb_allowin     (wb_allowin     ),
    .ma_allowin     (ma_allowin     ),
    .ma_validout    (ma_validout    ),
    .ex_to_ma_bus   (ex_to_ma_bus   ),
    .ma_to_wb_bus   (ma_to_wb_bus   ),
    .data_sram_rdata(data_sram_rdata)
);
wbstage wb_stage(
    .clk            (clk            ),
    .rst            (reset          ),
    .ma_validout    (ma_validout    ),
    .other_allowin  (other_allowin  ),
    .wb_allowin     (wb_allowin     ),
    .wb_validout    (wb_validout    ),
    .ma_to_wb_bus   (ma_to_wb_bus   ),
    .wb_regfile_bus (wb_regfile_bus ),
    .debug_wb_pc       (debug_wb_pc       ),
    .debug_wb_rf_we    (debug_wb_rf_we    ),
    .debug_wb_rf_wnum  (debug_wb_rf_wnum  ),
    .debug_wb_rf_wdata (debug_wb_rf_wdata )
);
endmodule

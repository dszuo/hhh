module vga(
rst_n,
vga_clk,
vga_hs,
vga_vs,
vga_r,
vga_g,
vga_b
);

input rst_n;
input vga_clk;
output vga_hs;
output vga_vs;
output [7:0] vga_r;
output [7:0] vga_g;
output [7:0] vga_b;

parameter LinePeriod =800;           //????
parameter H_SyncPulse=96;            //??????Sync a?
parameter H_BackPorch=48;             //?????Back porch b?
parameter H_ActivePix=640;            //??????Display interval c?
parameter H_FrontPorch=16;            //?????Front porch d?
parameter Hde_start=144;
parameter Hde_end  =784;

parameter FramePeriod =525;           //????
parameter V_SyncPulse=2;              //??????Sync o?
parameter V_BackPorch=31;             //?????Back porch p?
parameter V_ActivePix=480;            //??????Display interval q?
parameter V_FrontPorch=11;             //?????Front porch r?
parameter Vde_start=33;
parameter Vde_end  =513;

reg[9 : 0]  x_cnt;  
reg[9 : 0]  y_cnt;  
reg[7 : 0]  vga_r_reg;
reg[7 : 0]  vga_g_reg;
reg[7 : 0]  vga_b_reg;  
reg hsync_r;
reg vsync_r; 
reg hsync_de;
reg vsync_de;
  
wire [29:0] ram_add;       
wire [7:0] ram_data_r;
wire [7:0] ram_data_g;
wire [7:0] ram_data_b;
wire wr_en;
wire rd_en;

assign wr_en = 0;
assign rd_en = 1;
assign ram_add = (x_cnt - Hde_start) * 640 + (y_cnt - Vde_start);
assign vga_r = (hsync_de & vsync_de)?vga_r_reg:8'b00000000;
assign vga_g = (hsync_de & vsync_de)?vga_g_reg:8'b00000000;
assign vga_b = (hsync_de & vsync_de)?vga_b_reg:8'b00000000;
assign vga_hs = hsync_r;
assign vga_vs = vsync_r;

ram ram_r(
    .clk(vga_clk),
    .rst(rst_n),
    .wr_en_i(wr_en),
    .rd_en_i(rd_en),
    .addr_i(ram_add),
    .data_io(ram_data_r)
);

ram ram_g(
    .clk(vga_clk),
    .rst(rst_n),
    .wr_en_i(wr_en),
    .rd_en_i(rd_en),
    .addr_i(ram_add),
    .data_io(ram_data_g)
);

ram ram_b(
    .clk(vga_clk),
    .rst(rst_n),
    .wr_en_i(wr_en),
    .rd_en_i(rd_en),
    .addr_i(ram_add),
    .data_io(ram_data_b)
);

always @ (posedge vga_clk)
   begin
       if(~rst_n)    x_cnt <= 1;
       else if(x_cnt == LinePeriod) x_cnt <= 1;
       else x_cnt <= x_cnt+ 1;
   end

always @ (posedge vga_clk)
   begin
       if(~rst_n) hsync_r <= 1'b1;
       else if(x_cnt == 1) hsync_r <= 1'b0;            //??hsync??
       else if(x_cnt == H_SyncPulse) hsync_r <= 1'b1;
		 
		 		 
	    if(~rst_n) hsync_de <= 1'b0;
       else if(x_cnt == Hde_start) hsync_de <= 1'b1;    //??hsync_de??
       else if(x_cnt == Hde_end) hsync_de <= 1'b0;	
   end

always @ (posedge vga_clk)
   begin
       if(~rst_n) y_cnt <= 1;
       else if(y_cnt == FramePeriod) y_cnt <= 1;
       else if(x_cnt == LinePeriod) y_cnt <= y_cnt+1;
   end

always @ (posedge vga_clk)
  begin
       if(~rst_n) vsync_r <= 1'b1;
       else if(y_cnt == 1) vsync_r <= 1'b0;    //??vsync??
       else if(y_cnt == V_SyncPulse) vsync_r <= 1'b1;
		 
	    if(~rst_n) vsync_de <= 1'b0;
       else if(y_cnt == Vde_start) vsync_de <= 1'b1;    //??vsync_de??
       else if(y_cnt == Vde_end) vsync_de <= 1'b0;	 
  end

always @(negedge vga_clk)  
    if(~rst_n) begin 
        vga_r_reg<=0; 
        vga_g_reg<=0;
        vga_b_reg<=0;         
    end
   else
        begin   
	     if(vsync_de&hsync_de)  
             vga_r_reg<=ram_data_r;
             vga_g_reg<=ram_data_g;
             vga_b_reg<=ram_data_b;
         end    
endmodule

module ram(
    input                   clk,
    input                   rst,
    input                   wr_en_i,
    input                   rd_en_i,
    input [29:0]             addr_i,
    inout [7:0]            data_io
);

    reg [7:0]          bram[307199:0];    
    integer          i;   
    reg [7:0]       data;
 
    always @(posedge clk or posedge rst)
    begin
       if (~rst)   
         begin
           for(i=0;i<=921599;i=i+1)
           bram[i] <= 8'b1;
         end
       else if (wr_en_i) begin
            bram[addr_i] <= data_io;
       end
       else if (rd_en_i) begin
            data <= bram[addr_i];
       end
       else begin
        data <= 8'bz;       
       end
    end

    assign data_io = rd_en_i? data : 8'bz;
endmodule

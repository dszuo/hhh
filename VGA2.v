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
  
wire wr_en;
wire rd_en;

wire[95:0] font_data;
reg[7:0] font_addr;
wire[7:0] text_data;
reg[11:0] text_addr;

reg [7:0] font_idx;
reg [9:0] fram_x;
reg [8:0] fram_y;

assign wr_en = 0;
assign rd_en = 1;
assign ram_add = (x_cnt - Hde_start) * 640 + (y_cnt - Vde_start);
assign vga_r = (hsync_de & vsync_de)?vga_r_reg:8'b00000000;
assign vga_g = (hsync_de & vsync_de)?vga_g_reg:8'b00000000;
assign vga_b = (hsync_de & vsync_de)?vga_b_reg:8'b00000000;
assign vga_hs = hsync_r;
assign vga_vs = vsync_r;

ram ram(
    .clk(vga_clk),
    .rst(rst_n),
    .wr_en_i(wr_en),
    .rd_en_i(rd_en),
    .addr_i(text_addr),
    .data_io(text_data)
);

rom rom(
    .clk(vga_clk),
    .rst(rst_n),
    .addr_i(font_addr),
    .data_out(font_data)
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

always @(x_cnt or y_cnt)
   begin
	if(vsync_de&hsync_de) begin
		fram_x <= x_cnt - Hde_start;
		fram_y <= y_cnt - Vde_start;
	end
	else begin
		fram_x <= 0;
		fram_y <= 0;
	end
   end

always @(fram_x or fram_y) begin
	if(hsync_de&vsync_de) begin
		text_addr <= (fram_x / 8) + (fram_y / 12) * 80;
		font_idx <= (fram_x % 8) + (fram_y % 12) * 8;
	end
end

always @(negedge vga_clk)  begin
    if(~rst_n) begin 
        vga_r_reg<=0; 
        vga_g_reg<=0;
        vga_b_reg<=0;         
    end
   else
        begin   
	     if(vsync_de&hsync_de)  
             vga_r_reg<=font_data[font_idx];
             vga_g_reg<=font_data[font_idx];
             vga_b_reg<=font_data[font_idx];
         end  
	end  
endmodule

module ram(
    input                   clk,
    input                   rst,
    input                   wr_en_i,
    input                   rd_en_i,
    input [11:0]             addr_i,
    inout [7:0]            data_io
);

    reg [7:0]          bram[3199:0];    
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

module rom(
    input                  clk,
    input                  rst,
    input [7:0]            addr_i,
    output [95:0]          data_out
);
    reg [95:0]          rom[255:0];  
    reg [95:0]	data; 
    assign data_out = data;
    integer          i;
    always @(posedge clk or posedge rst)
    begin
       if (~rst)   
         begin
	   rom[0] <= 96'hFFFFFF;
           for(i=1;i<=255;i=i+1)
           	rom[i] <= 95'b0; 
         end
       else data <= rom[addr_i];
    end
endmodule

/*
 * Milkymist SoC
 * Copyright (C) 2007, 2008, 2009, 2010, 2011 Sebastien Bourdeauducq
 * Copyleft 2011 Cristian Paul Pe~naranda Rojas
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

module tb_gpsreceiver();

   parameter PERIOD          = 20;
   parameter real DUTY_CYCLE = 0.5;
   parameter real DUTY_CYCLE2 = 0.5;
   parameter DATA_OFFSET          = 80;
   parameter OFFSET          = 0;
   parameter TSET            = 3;
   parameter THLD            = 3;
   parameter NWS             = 3;

   initial begin  // Initialize GPS Receiver Outs
	gps_rec_clk = 0;
	gps_rec_sync = 0;
	gps_rec_data = 0;
   end

   initial  begin  // Process for clk 8Mhz?
     forever
       begin
         gps_rec_clk = 1'b0;
         #(PERIOD-(PERIOD*DUTY_CYCLE)) gps_rec_clk = 1'b1;
         #(PERIOD*DUTY_CYCLE);
       end
   end


   initial  begin  // Process for data, a loop of 1 2 4 8...
     forever
       begin
         gps_rec_data = 1'b0;
         #((PERIOD+DATA_OFFSET)-(PERIOD*DUTY_CYCLE)) gps_rec_data = 1'b1;
         #(PERIOD*DUTY_CYCLE);
       end
   end

   initial  begin  // Process for sync clk/4
     forever
       begin
         gps_rec_sync = 1'b0;
         #((PERIOD+60)-(PERIOD*DUTY_CYCLE)) gps_rec_sync = 1'b1;
         #(PERIOD*DUTY_CYCLE);
       end
   end


//100MHz system clock 
reg sys_clk;
initial sys_clk = 1'b0;
always #5 sys_clk = ~sys_clk;

/* 8MHz RX clock 
reg gps_rec_clk;
initial gps_rec_clk = 1'b0;
always #20 gps_rec_clk = ~gps_rec_clk;

/* Sync 
reg reg_gps_rec_sync;
initial gps_rec_sync = 1'b0;
always #60 gps_rec_sync = ~gps_rec_sync;
*/

reg sys_rst;

reg [14:0] csr_a;
reg csr_we;
reg [31:0] csr_di;
wire [31:0] csr_do;

reg [31:0] wb_adr_i;
reg [31:0] wb_dat_i;
wire [31:0] wb_dat_o;
reg wb_cyc_i;
reg wb_stb_i;
reg wb_we_i;
wire wb_ack_o;

reg gps_rec_data;
reg gps_rec_sync;
reg gps_rec_clk;

gpsreceiver2 #(
	.csr_addr(5'h0)
) gpsreceiver (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_di),
	.csr_do(csr_do),
	
	.wb_adr_i(wb_adr_i),
	.wb_dat_i(wb_dat_i),
	.wb_dat_o(wb_dat_o),
	.wb_cyc_i(wb_cyc_i),
	.wb_stb_i(wb_stb_i),
	.wb_we_i(wb_we_i),
	.wb_sel_i(4'hf),
	.wb_ack_o(wb_ack_o),

	.gps_rec_clk(gps_rec_clk),
	.gps_rec_data(gps_rec_data),
	.gps_rec_sync(gps_rec_sync)
);

task waitclock;
begin
	@(posedge sys_clk);
	#1;
end
endtask

/*task csrwrite;
input [31:0] address;
input [31:0] data;
begin
	csr_a = address[16:2];
	csr_di = data;
	csr_we = 1'b1;
	waitclock;
	$display("Configuration Write: %x=%x", address, data);
	csr_we = 1'b0;
end
endtask
*/
task csrread;
input [31:0] address;
begin
	csr_a = address[16:2];
	waitclock;
	$display("Configuration Read : %x=%x", address, csr_do);
end
endtask

task wbwrite;
input [31:0] address;
input [31:0] data;
integer i;
begin
	wb_adr_i = address;
	wb_dat_i = data;
	wb_cyc_i = 1'b1;
	wb_stb_i = 1'b1;
	wb_we_i = 1'b1;
	i = 0;
	while(~wb_ack_o) begin
		i = i+1;
		waitclock;
	end
	waitclock;
	$display("WB Write: %x=%x acked in %d clocks", address, data, i);
	wb_cyc_i = 1'b0;
	wb_stb_i = 1'b0;
	wb_we_i = 1'b0;
end
endtask

task wbread;
input [31:0] address;
integer i;
begin
	wb_adr_i = address;
	wb_cyc_i = 1'b1;
	wb_stb_i = 1'b1;
	wb_we_i = 1'b0;
	i = 0;
	while(~wb_ack_o) begin
		i = i+1;
		waitclock;
	end
	$display("WB Read : %x=%x acked in %d clocks", address, wb_dat_o, i);
	waitclock;
	wb_cyc_i = 1'b0;
	wb_stb_i = 1'b0;
	wb_we_i = 1'b0;
end
endtask

/*integer cycle;
initial cycle = 0;
*always @(posedge gps_rec_clk) begin
	cycle <= cycle + 1;
	gps_rec_data <= cycle;
	if(gps_rec_sync) begin
		//$display("rx: %x", gps_rec_data);
		if((cycle % 16) == 16) begin
			gps_rec_data <= 1'b0;
			//$display("** stopping transmission");
		end
	        /* having a loop-like cycle, like a parallel to serial module */
//	end
//end

/*always @(posedge phy_tx_clk) begin
	if(phy_tx_en)
		$display("tx: %x", phy_tx_data);
end*/

initial begin
	/* Reset / Initialize our logic */
	sys_rst = 1'b1;

	csr_a = 15'd0;
	csr_di = 32'd0;
	csr_we = 1'b0;
	gps_rec_sync = 1'b0;

	waitclock;

	sys_rst = 1'b0;

	$dumpvars(0, gpsreceiver);
	$dumpfile("gpsreceiver.vcd");


	waitclock;

	#2000;
	wbread(32'h0000);
	#2010;
	wbread(32'h0001);
	#2020;
	wbread(32'h0002);
	#2030;
	wbread(32'h0003);
	#5040;
	wbread(32'h0004);
	#2050;
	wbread(32'h0005);
	#2060;
	wbread(32'h0006);
	#2070;
	wbread(32'h0007);

	//csrwrite(32'h00, 0);
	//csrwrite(32'h08, 1);
	wbwrite(32'h1000, 32'h12345678);
	wbread(32'h1000);
	//wbwrite(32'h0000, 32'h12345678);

	//csrwrite(32'h18, 10);
	//csrwrite(32'h10, 1);

	
	//csrread(32'h08);
	//csrread(32'h0C);
	//csrread(32'h10);
	//csrread(32'h14);
	
/*	wbread(32'h0800);
	wbread(32'h0804);
	wbread(32'h0808);
	*/

	
	$finish;
end

endmodule

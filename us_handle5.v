module us_handle5(
	//системные сигналы
	input						clk50,				//50 МГц входная частота (PLL2 для MCLK_ADC)
	input 						clk50_1,			//50 МГц входная частота (PLL3 для MCLK_ADC_LOG)
	output 						alt_rdy,			//самосброс для работы должен быть 1
	input 						reset_n,			//соединен с alt_rdy
	
	//тестовые светодиоды
	output		[1:0] 			tled,
	
	//энкодеры
	input		[1:0]			enc_a,				//энкодер фаза A
	input		[1:0]			enc_b,				//энкодер фаза B
	input		[1:0]			enc_sw,				//энкодер кнопка 0 - нажата
	
	//кнопки матрица 2 выхода на 3 входа
	output		[1:0]			scan,				//линии сканирования должны быть open drain (активный 0)
	input		[2:0]			key,				//входы от кнопок (подтянуты к 1)
	
	//интерфейс GPS
	input 						gps_rx,
	output 						gps_tx,
	
	//интерфейс контроллера питания (и СОВЫ)
	input 						alt_rx,
	output 						alt_tx,

	//интерфейс PHY
	input 						refclk,				//референсный тактовый сигнал 50 МГц
	output		[1:0]			txd,
	output 						tx_en,
	input 		[1:0]			rxd,
	input						crs_dv,
	inout						mdio,
	output						mdc,
	output						phy_rst,			//сброс PHY
	
	//интерфейс линейного канала
	output 						mclk_adc,			//тактовая частота АЦП (выход PLL2)
	input		[11:0]			d_lin,				//данные линейного канала
	output		[1:0]			ddac_lin,			//входные данные ЦАП
	output						syncn_lin,			//строб ЦАП
	output						sclk_lin,			//тактовая ЦАП
	output		[1:0]			flt_sel,			//выбор фильтра (00 - 100КГц, 01 - 500КГц, 10 - 2.5МГц, 11 - 5МГц)
	output						lohi,				//выбор генератора зондирования (0 - ВЧ, 1 - НЧ)
	output						rscom_lin,			//переключение искателя (0 - RS, 1 - совмещенный)
	
	//интерфейс логарифмического канала
	output						mclk_adc_log,		//тактовая частота АЦП (выход PLL3)
	input		[9:0]			d_log,				//данные логарифмического канала
	output						ddac_log,			//входные данные ЦАП
	output						syncn_log,			//строб ЦАП
	output						sclk_log,			//тактовая ЦАП
	output						rscom_log,			//переключение искателя (0 - RS, 1 - совмещенный)
	
	//сигналы генератора зондирования ВЧ (0 - верхний, 1 - нижний)
	output		[1:0]			zpwr_on,			//1 - включение питания на катушку
	output		[1:0]			zndhi,				//управление транзистором ударника
	
	//сигналы генератора зондирования НЧ
	output		[1:0]			zndlow,				//управление транзисторами генератора
	
	//дополнительные входы - выходы
	inout		[7:0]			io 
);

	//снять reset
	assign alt_rdy = 1'b1;
	//------------------------------------
	//временные заглушки на сигналы во избежание лишнего потребления
	//assign phy_rst = 1'b1;
	assign scan = 2'bzz;
	assign zpwr_on = 2'b00;
	assign zndhi = 2'b00;
	assign zndlow = 2'b00;
	assign rscom_lin = 1'b0;
	assign rscom_log = 1'b0;
	assign lohi = 1'b0;
	//-------------------------------------

	//test
	reg [31:0] t_count;
	assign tled = ~t_count[23:22];
	always@(posedge clk50)
	begin
		t_count <= t_count + 1'b1;
	end

	

	wire						phy_rst_n;
	assign phy_rst = phy_rst_n;

	wire						rst_n;
	wire						sys_clk;
		
	wire						pll_txclk;
	eth_pll eth_pll_unit(
		.inclk0(clk50),
		//.c0(pll_txclk),
		//.c1(rgmii_rxclk),
		
		//.c2(refclk),
		
		.locked(phy_rst_n)
	);
	
	wire						adc_clk;
	wire						log_clk;
	wire						dac_clk;
	wire						hi_clk;
	main_pll main_pll_unit(		
		.inclk0(clk50),
		
		.c0(sys_clk),
		
		.c1(adc_clk),
		.c2(log_clk),
		.c3(dac_clk),
		.c4(hi_clk),

		.locked(rst_n)
	);
	
	//------------------------------------------------------------------------
	//	Ethernet 10/100
	//------------------------------------------------------------------------
	
	wire		[15:0]			frame_size;
	assign frame_size = 1024;
	
	reg			[23:0]			cntr;
	always @ (posedge sys_clk) cntr <= cntr + 1'd1;
	
	reg			[1:0]			sync_rise;
	always @ (posedge sys_clk) sync_rise <= {sync_rise[0], cntr[23]};
	
	wire		[31:0]			packet_data;
	wire						packet_vld;
	wire						packet_rdy;
	wire						packet_ready;
	wire		[15:0]			packet_size;

	emac_eth emac_eth_unit(
		.rst_n(rst_n),
		.sysclk(sys_clk),
		
		.i_sync(packet_ready),
		
		.i_frame_data(packet_data),
		.i_frame_vld(packet_vld),
		.o_frame_rdy(packet_rdy),
		
		.i_frame_size(packet_size_size),
		
		.i_refclk(refclk),
		//.o_refclk(refclk),
		
		//.o_ephy_rst_n(ephy1_rstn),
		
		.i_rxd(rxd),
		.i_rxdv(crs_dv),
		//.i_rxer(rmii_rxer),
		
		.o_txd(txd),
		.o_txen(tx_en),
		
		.o_mdc(mdc),
		.io_mdio(mdio)
	);
	
	main main_u(
		.rst_n(rst_n),
		.sys_clk(sys_clk),
		.adc_clk(adc_clk),
		.log_clk(log_clk),
		.dac_clk(dac_clk),
		.hi_clk(hi_clk),
		
		.i_sys_sync(sync_rise == 2'b01),
		
		.o_packet_data(packet_data),
		.o_packet_vld(packet_vld),
		.i_packet_rdy(packet_rdy),
		
		.o_packet_ready(packet_ready),
		.o_packet_size(packet_size)
	);

endmodule

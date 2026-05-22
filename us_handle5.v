module us_handle5(
//системные сигналы
input clk50,				//50 МГц входная частота (PLL2 для MCLK_ADC)
input clk50_1,				//50 МГц входная частота (PLL3 для MCLK_ADC_LOG)
output alt_rdy,			//самосброс для работы должен быть 1
input reset_n,				//соединен с alt_rdy
//тестовые светодиоды
output [1:0] tled,
//энкодеры
input [1:0] enc_a,		//энкодер фаза A
input [1:0] enc_b,		//энкодер фаза B
input [1:0] enc_sw,		//энкодер кнопка 0 - нажата
//кнопки матрица 2 выхода на 3 входа
output [1:0] scan,		//линии сканирования должны быть open drain (активный 0)
input [2:0] key,			//входы от кнопок (подтянуты к 1)
//интерфейс GPS
input gps_rx,
output gps_tx,
//интерфейс контроллера питания (и СОВЫ)
input alt_rx,
output alt_tx,
//интерфейс PHY
input refclk,				//референсный тактовый сигнал 50 МГц
output [1:0] txd,
output tx_en,
input [1:0] rxd,
input crs_dv,
inout mdio,
output mdc,
output phy_rst,			//сброс PHY
//интерфейс линейного канала
output mclk_adc,			//тактовая частота АЦП (выход PLL2)
input [11:0] d_lin,		//данные линейного канала
output [1:0] ddac_lin,	//входные данные ЦАП
output syncn_lin,			//строб ЦАП
output sclk_lin,			//тактовая ЦАП
output [1:0] flt_sel,	//выбор фильтра (00 - 100КГц, 01 - 500КГц, 10 - 2.5МГц, 11 - 5МГц)
output lohi,				//выбор генератора зондирования (0 - ВЧ, 1 - НЧ)
output rscom_lin,			//переключение искателя (0 - RS, 1 - совмещенный)
//интерфейс логарифмического канала
output mclk_adc_log,		//тактовая частота АЦП (выход PLL3)
input [9:0] d_log,		//данные логарифмического канала
output ddac_log,			//входные данные ЦАП
output syncn_log,			//строб ЦАП
output sclk_log,			//тактовая ЦАП
output rscom_log,			//переключение искателя (0 - RS, 1 - совмещенный)
//сигналы генератора зондирования ВЧ (0 - верхний, 1 - нижний)
output [1:0] zpwr_on,	//1 - включение питания на катушку
output [1:0] zndhi,		//управление транзистором ударника
//сигналы генератора зондирования НЧ
output [1:0] zndlow,		//управление транзисторами генератора
//дополнительные входы - выходы
inout [7:0] io 
);
//снять reset
assign alt_rdy = 1'b1;
//------------------------------------
//временные заглушки на сигналы во избежание лишнего потребления
assign phy_rst = 1'b1;
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

endmodule

vlib work

vlog Single_Port_Synchronous_RAM.v SPI_Slave_Interface.v SPI_Top_Module.v

vlog SPI_Top_Module_tb.v

vsim -voptargs="+acc" work.SPI_Top_module_tb 

# for the DUT signals
# add wave /DUT/*
# for the internal signals each on its own 
# add wave -position insertpoint sim:/SPI_Top_module_tb/DUT/SPI/*
# add wave -position insertpoint sim:/SPI_Top_module_tb/DUT/RAM/*

add wave -position insertpoint \
    sim:/SPI_Top_module_tb/DUT/clk \
    sim:/SPI_Top_module_tb/Input_Data_Address \
    sim:/SPI_Top_module_tb/DUT/MOSI \
    sim:/SPI_Top_module_tb/DUT/SS_n \
    sim:/SPI_Top_module_tb/DUT/a_rst_n \
    sim:/SPI_Top_module_tb/DUT/SPI/NS \
    sim:/SPI_Top_module_tb/DUT/SPI/CS \
    sim:/SPI_Top_module_tb/DUT/MISO \
    sim:/SPI_Top_module_tb/DUT/SPI/mid_data \
    sim:/SPI_Top_module_tb/DUT/SPI/Check_READ_ADD_flag \
    sim:/SPI_Top_module_tb/DUT/rx_data \
    sim:/SPI_Top_module_tb/DUT/rx_valid \
    sim:/SPI_Top_module_tb/DUT/RAM/din \
    sim:/SPI_Top_module_tb/DUT/RAM/Addr_wr \
    sim:/SPI_Top_module_tb/DUT/RAM/Addr_rd \
    sim:/SPI_Top_module_tb/DUT/tx_data \
    sim:/SPI_Top_module_tb/DUT/RAM/dout \
    sim:/SPI_Top_module_tb/DUT/tx_valid \
    sim:/SPI_Top_module_tb/DUT/SPI/Counter \
    sim:/SPI_Top_module_tb/DUT/RAM/i 

run -all

mem save -o RAM.mem -f mti -data symbolic -addr hex /SPI_Top_module_tb/DUT/RAM/RAM

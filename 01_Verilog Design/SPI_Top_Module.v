module SPI_Top_module(
    /* ---------------------- Input Ports ---------------------- */
    /* Input from Master (Master-out-Slave-in) */
    input MOSI,

    /* Activating the slave communication */  
    input SS_n,

    /* Clock Signal */
    input clk,

    /* Active Low asynchronous reset */
    input a_rst_n,

    /*  ---------------------- Output Ports  ---------------------- */
    /* Input to Master (Master-in-Slave-out) */
    output MISO
);
    /*  --------------------- Internal Signals  ------------------- */
    /* Receiving Data to RAM */
    wire [9:0] rx_data;
    wire rx_valid;

    /* Transmitting Data to RAM */
    wire [7:0] tx_data;
    wire tx_valid;

    /*  ------------------- Modules Instantiation  ---------------- */
    /* SPI Slave Module */
    SPI_Slave_Interface SPI (
        .MISO(MISO),
        .MOSI(MOSI),
        .SS_n(SS_n),
        .clk(clk),
        .a_rst_n(a_rst_n),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .tx_data(tx_data),
        .tx_valid(tx_valid)
    );
    
    /* RAM Module */
    Single_Port_Synchronous_RAM RAM(
        .clk(clk),
        .a_rst_n(a_rst_n),
        .din(rx_data),
        .rx_valid(rx_valid),
        .dout(tx_data),
        .tx_valid(tx_valid)
    );

endmodule
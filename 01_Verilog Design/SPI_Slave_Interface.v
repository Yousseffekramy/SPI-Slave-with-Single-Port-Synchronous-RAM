module SPI_Slave_Interface (
    /* ---------------------- Input Ports ---------------------- */
    /* Input from Master (Master-out-Slave-in) */
    input MOSI,

    /* Activating the slave communication 
        "0" ==> Start the communication
        "1" ==> End Communication */  
    input SS_n,

    /* Clock Signal */
    input clk,

    /* Active Low asynchronous reset */
    input a_rst_n,

    /* Transmitted Data from RAM */
    input [7:0] tx_data,

    /* Signal for validity of tx */
    input tx_valid,

    /*  ---------------------- Output Ports  ---------------------- */
    /* Input to Master (Master-in-Slave-out) */
    output reg MISO,

    /* Output to the data to be written in RAM */
    output reg [9:0] rx_data,

    /* Signal for validity of rx */
    output reg rx_valid
);
    /*  --------------------- Internal Signals  ------------------- */
    /* Flag if read address done before read data */
    reg Check_READ_ADD_flag;

    /* Counter for Converting Serial to Parallel to tx_data port 
                   Converting Parallel to Series from rx_data port */
    integer Counter = 0;

    /* Storage register for the data used in conversion of Serial to 
       Parallel or vice versa */
    reg [8:0] mid_data;

    /* Signal for knowing if it is first time to enter READ_DATA */
    reg READ_DATA_First_time;
    
    /*  ---------------------- FSM States  ------------------------ */

    /* Defining FSM States Parameters */
    localparam IDLE = 'b001;
    localparam CHK_CMD = 'b010;
    localparam WRITE = 'b100;
    localparam READ_ADD = 'b110;
    localparam READ_DATA = 'b101;

    /* Register for Next and Current States */
    (* fsm_encoding = "gray" *)
    reg [2:0] CS, NS;


    /*  -------------------- Next State Logic  -------------------- */
    always @(*) begin
        case (CS)
            IDLE: 
                begin
                    if(~a_rst_n)
                        NS = IDLE;
                    else if(SS_n)
                        NS = IDLE;
                    else if(~SS_n)
                        NS = CHK_CMD;
                    else
                        NS = IDLE;
                end
            CHK_CMD:
                begin
                    if(SS_n)
                        NS = IDLE;
                    else if((SS_n == 0) && (MOSI == 0))
                        NS = WRITE;
                    else if((SS_n == 0) && (MOSI == 1)) begin
                        /* Check if Read Address is done first or not */
                        if(Check_READ_ADD_flag) begin
                            NS = READ_DATA;
                        end
                        else begin
                            NS = READ_ADD;
                        end
                    end
                    else
                        NS = CHK_CMD;
                end
            WRITE:
                begin
                    if(SS_n)
                        NS = IDLE;
                    else
                        NS = WRITE;
                end
            READ_ADD:
                begin
                    if(SS_n)
                        NS = IDLE;
                    else
                        NS = READ_ADD;
                end
            READ_DATA:
                begin
                    if(SS_n)
                        NS = IDLE;
                    else 
                        NS = READ_DATA;
                end
            default: 
                begin
                    NS = IDLE;
                end
        endcase
    end

    /*  ---------------------- State Memory  ---------------------- */
    always @(posedge clk) begin
        if(~a_rst_n) begin
            /* Reset Current State */
            CS <= IDLE;
        end
        else begin
            /* Assign the next state in the Current state */
            CS <= NS;
        end
    end

    /*  ---------------------- Output Logic  ---------------------- */
    always @(posedge clk) begin
        if(~a_rst_n) begin
            /* Reset Outputs */
            MISO <= 0;
            rx_data <= 0;
            rx_valid <= 0;
            Counter <= 0;
            READ_DATA_First_time <= 1;
            Check_READ_ADD_flag <= 0;

        end
        else begin
            /* Assign Outputs */
            case(CS)
            IDLE:
                begin
                    /* Reset Outputs */
                    MISO <= 0;
                    rx_data <= 0;
                    rx_valid <= 0;
                    Counter <= 0;
                    READ_DATA_First_time <= 1;
                end
            CHK_CMD:
                begin
                    /* Reset Outputs */
                    MISO <= 0;
                    rx_data <= 0;
                    rx_valid <= 0;             
                end
            WRITE:
                begin
                    if(Counter < 9) begin
                        /* Receives Serial Data in Mid-data register */
                        mid_data <= (mid_data << 1) + MOSI;
                        Counter <= Counter + 1;
                    end
                    else begin
                        /* Completes receiving and send the mid-data 
                            to RAM to be stored (either address or 
                            data as the RAM will detect the behavior
                            according to rx_data 2 MSBs )  */
                        rx_data <= (mid_data << 1) + MOSI;
                        rx_valid <= 1;
                        Counter <= 0;
                        mid_data <= 0;
                    end
                end
            READ_ADD:
                begin
                    if(Counter < 9) begin
                        /* Receives Serial Address in Mid-data register */
                        mid_data <= (mid_data << 1) + MOSI;
                        Counter <= Counter + 1;
                    end
                    else begin
                        /* Completes receiving and send the mid-data 
                            to RAM to detect which Address will be 
                            read */                     
                        rx_data <= (mid_data << 1) + MOSI;
                        rx_valid <= 1;
                        Check_READ_ADD_flag <= 1;
                        Counter <= 0;
                        mid_data <= 0;
                    end
                end
            READ_DATA:
                begin
                    /* Read instruction completely */
                    if((Counter < 9) && READ_DATA_First_time) begin
                        mid_data <= (mid_data << 1) + MOSI;
                        Counter <= Counter + 1;
                    end
                    else 
                        /* Completes receiving and send the mid-data 
                            to RAM */   
                        if((Counter == 9) && READ_DATA_First_time) begin                 
                            rx_data <= (mid_data << 1) + MOSI;
                            rx_valid <= 1;
                            Counter <= 0;
                            READ_DATA_First_time <= 0;
                        end
                    else
                        if(tx_valid && Check_READ_ADD_flag && (~READ_DATA_First_time)) begin
                            /* Check if address is sent or not to the RAM 
                            for successful operation */

                            if(Counter < 8) begin
                                /* Converts Parallel data to Serial to be 
                                    sent to Master */
                                MISO <= tx_data [Counter];
                                Counter <= Counter + 1;
                            end
                            else begin
                                /* Completes sending successfully and resets 
                                the address flag and counter */
                                Check_READ_ADD_flag <= 0;
                                READ_DATA_First_time <= 1;
                                Counter <= 0; 
                                mid_data <= 0;
                            end
                        end 
                end
            default:
                begin
                    /* To avoid any other invalid CS will reset outputs 
                       without changing any related internal signals to 
                       be able to continue functionality again */
                    MISO <= 0;
                    rx_data <= 0;
                    rx_valid <= 0;
                end       
            endcase
        end
    end
endmodule
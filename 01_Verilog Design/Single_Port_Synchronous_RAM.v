module Single_Port_Synchronous_RAM #(
    /* ---------------------- Design Parameters ---------------------- */
    /* Width of the word in memory */
    parameter MEM_WIDTH = 8,

    /* Depth of the memory (No of words in memory) */
    parameter MEM_DEPTH = 256,

    /* Address of the location in memory 
       (calculated by HDL compiler using $clog2(..)) */
    parameter MEM_ADDR_WIDTH = $clog2(MEM_DEPTH)

) (
    /* ---------------------- Input Ports ---------------------- */
    /*  [9:8] MODE SELECTION
        ------------------------------------------------------------
        00   ==>       ==> Hold din[7:0] internally as write address
                 Write
        01   ==>       ==> Write din[7:0] in the memory with write 
                           address held previously
        ------------------------------------------------------------
        10   ==>       ==> Hold din[7:0] internally as read address
                 Read
        11   ==>       ==> Read the memory with read address held 
                           previously, tx_valid should be HIGH,
                           dout holds the word read from the memory
                           ignore din[7:0]
        ----------------------------------------------------------- */
    input [MEM_WIDTH+1:0] din,

    /* Clock Signal */
    input clk,

    /* Active Low asynchronous reset */
    input a_rst_n,

    /* HIGH ==> Accept din[7:0] to save the R/W address internally
                OR 
                Write a memory word depending on the 2 MSBs din[9:8] */
    input rx_valid,

    /*  ---------------------- Output Ports  ---------------------- */
    /* Data Output */
    output reg [MEM_WIDTH-1:0] dout,

    /* Whenever the command is memory read the tx_valid is HIGH */
    output reg tx_valid
);
    /* Create the RAM block */
    (* ram_style = "block" *) reg [MEM_WIDTH-1:0] RAM [MEM_DEPTH-1:0];

    /* Register holder for R/W addresses */
    reg [MEM_ADDR_WIDTH-1:0] Addr_rd, Addr_wr;

    /* Controller for reset RAM for loop */
    integer i;

    /* Single port Synchronous RAM logic */
    always @(posedge clk) begin
        if(~a_rst_n) begin
            /* Initialize all RAM by zeroes */
            /*for (i = 0; i<MEM_DEPTH; i = i + 1) begin
                RAM[i] <= {MEM_WIDTH{1'b0}};
            end*/

            /* Give the outputs zero value */
            dout <= 0;
            tx_valid <= 0;

            /* Internal Signals */
            Addr_rd <= 0;
            Addr_wr <= 0;
        end
        else begin
            case(din[9:8])
                /* Write Functionality */
                2'b00: begin
                    if(rx_valid)
                        Addr_wr <= din[7:0];
                        
                end
                2'b01: begin
                    if(rx_valid)
                        RAM[Addr_wr] <= din[7:0];
                        
                end

                /* Read Functionality */
                2'b10: begin
                    Addr_rd <= din[7:0];
                end
                
                2'b11: begin
                    dout <= RAM[Addr_rd];
                end
            endcase

            /* assign tx_valid value according to Opcode in din */
            if(din[9:8] == 2'b11)
                tx_valid <= 1;
            else
                tx_valid <= 0;
        end

    end
endmodule
module SPI_Top_module_tb();
    /* ---------------------- Input Ports ----------------------- */
    /* Input from Master (Master-out-Slave-in) */
    reg MOSI;

    /* Activating the slave communication */  
    reg SS_n;

    /* Clock Signal */
    reg clk;

    /* Active Low asynchronous reset */
    reg a_rst_n;

    /*  ---------------------- Output Ports  ---------------------- */
    /* Input to Master (Master-in-Slave-out) */
    wire MISO;

    /*  --------------------- Internal Signal  --------------------- */
    /* Register to hold data input to module */
    reg [9:0] Input_Data_Address; 
    /* Register to hold data output from module */
    reg [7:0] Data_module;
    /* Controller for the for loops */
    integer i;   
    
    /*  ------------------ Module Instantiation  -------------------- */
    SPI_Top_module DUT (
        .MOSI(MOSI),
        .SS_n(SS_n),
        .clk(clk),
        .a_rst_n(a_rst_n),
        .MISO(MISO)
        );
    
    /* --------------------- Clock Generation ----------------------*/
    initial begin
        clk = 0;
        forever begin
            #20;                  // 20 ns period => 50 MHz frequency
            clk = ~clk; 
        end
    end

    /* ------------------- Testbench Test Cases --------------------*/
    initial begin
        $display("START THE SIMULATION");

        /* Test Case 1: Check Reset Functionality */
        $display("Test Case 1: Check Reset Functionality");
        a_rst_n = 0;            // Active Low Reset
        repeat(3) @(negedge clk);
        self_checking_task(MISO, 0);
        a_rst_n = 1;            // Release Reset

        /* Test Case 2: Slave is not selected */
        $display("TEST CASE 2: Slave is not selected");
        SS_n = 1;               // Slave not selected
        repeat(3) @(posedge clk);
        self_checking_task(MISO, 0);

        /* Test Case 3: Send Write address and Data in this address */
        $display("TEST CASE 3: Send Write address and Data in this address ");
        SS_n = 1;               // Slave not selected
        MOSI = 0;               
        @(negedge clk);

        SS_n = 0;               // Slave selected
        @(negedge clk);

        /*     "00"     ==> Write Address Command
            "1010_1100" ==>   Address Selected  (AC)  */
        Input_Data_Address = 10'b00_1010_1100;

        for(i=0; i<10; i=i+1) begin
            @(negedge clk);
            MOSI = Input_Data_Address[9-i];
        end

        @(negedge clk);         // Ensure data is stable
        MOSI = 0;               // Clear MOSI
        @(negedge clk);         // Hold SS_n low for one more clock cycle
        SS_n = 1;               // Stop communication 
        repeat(3) @(negedge clk);

        SS_n = 0;               // Slave selected
        @(negedge clk);

        /*     "01"     ==> Write Data Command
            "1110_1110" ==>  Data Added     (EE)    */
        Input_Data_Address = 10'b01_1110_1110;

        for(i=0; i<10; i=i+1) begin
            @(negedge clk);
            MOSI = Input_Data_Address[9-i];
        end

        @(negedge clk);        // Ensure data is stable
        MOSI = 0;              // Clear MOSI
        @(negedge clk);        // Hold SS_n low for one more clock cycle
        SS_n = 1;              // Stop communication 
        repeat(3) @(negedge clk);

        $display("Check address 'hAC and data '1110_1110' written in it in RAM");
        // $stop;

        /* TEST CASE 4: Send Read address and Read Data in this address */
        $display("TEST CASE 4: Send Read address and Read Data in this address ");

        /*     "10"     ==> Read Address Command
           "1010_1100"  ==>   Address Selected    */
        Input_Data_Address = 10'b10_1010_1100;

        SS_n = 0;
        @(negedge clk);
        MOSI = Input_Data_Address[9]; 
        @(negedge clk); // More delay for processing

        for(i=1; i<10; i=i+1) begin
            @(negedge clk);
            MOSI = Input_Data_Address[9-i];
        end
        
        @(negedge clk);        // Ensure data is stable
        MOSI = 0;               // Clear MOSI
        @(negedge clk);         // Hold SS_n low for one more clock cycle
        SS_n = 1;               //Stop communication 
        repeat(3) @(negedge clk);


        /*     "11"     ==> Read Data Command
            "1011_1100" ==>   Redundant bits      */
        Input_Data_Address = 10'b11_1011_1100;
        
        SS_n = 0;               // Slave selected
        @(negedge clk);

        MOSI = Input_Data_Address[9]; 
        repeat(2) @(negedge clk); // More delay for processing

        for(i=1; i<10; i=i+1) begin
            @(negedge clk);
            MOSI = Input_Data_Address[9-i];  
        end

        @(negedge clk);        // Ensure data is stable

        for(i=0; i<8; i=i+1) begin
            @(negedge clk);
            Data_module[i] = MISO;
        end

        self_checking_8_bit_task(Data_module, 'b1110_1110);

        @(negedge clk);        // Ensure data is stable
        MOSI = 0;              // Clear MOSI        
        SS_n = 1;              //Stop communication 
        repeat(3) @(negedge clk);

        $display("END THE SIMULATION");
        $stop;
    end

    /* ------------------ Self-Checking 1-bit Task -------------------*/
    task self_checking_task;
        input module_out;
        input tb_required;
        begin
            // Check if the output is correct
            if (module_out == tb_required) begin
                $display("Self-checking task: Output is correct");
                end 
            else begin
                $display("Self-checking task: Output is incorrect \n");
                $display("module_out = %b, tb_required = %b", module_out,tb_required);
                $stop;
            end
        end
    endtask

    /* ------------------- Self-Checking 8-bit Task -------------------*/
    task self_checking_8_bit_task;
        input [7:0] module_out;
        input [7:0] tb_required;
        begin
            // Check if the output is correct
            if (module_out == tb_required) begin
                $display("Self-checking task: Output is correct");
                end 
            else begin
                $display("Self-checking task: Output is incorrect \n");
                $display("module_out = %b, tb_required = %b", module_out,tb_required);
                $stop;
            end
        end
    endtask
endmodule

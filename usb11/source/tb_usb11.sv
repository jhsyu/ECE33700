//  Module: tb_usb11
//
`timescale 1ns / 10ps
module tb_usb11();
    logic tb_clk;
    logic tb_n_rst;
    logic tb_d_plus;
    logic tb_d_minus;
    logic tb_r_enable;
    logic tb_empty;
    logic tb_full;
    logic tb_rcving;
    logic tb_r_error;

    logic [7:0] tb_r_data;
    logic [7:0] tb_test_byte;

    logic [3:0] tb_PID;
    logic [3:0] tb_expected_PID;
  
    integer test_num;
    integer count_1; 
    integer bit_num; 
    string test_info;

    localparam CLK_PERIOD = 1; 

    // Clock generation block
    always begin
        tb_clk = 1'b0;
        #(CLK_PERIOD/2.0);
        tb_clk = 1'b1;
        #(CLK_PERIOD/2.0);
    end


    task reset; begin
        @(negedge tb_clk); 
        tb_n_rst = 1'b0; 
        tb_d_plus = 1;
        tb_d_minus = 0;
        @(posedge tb_clk);
        #(CLK_PERIOD); 
        @(negedge tb_clk); 
        tb_n_rst = 1'b1; 
        @(negedge tb_clk); 
    end
    endtask

    task send_bit(
        input logic bit_to_send
    ); begin
        bit_num ++; 
        if (bit_to_send) begin
            count_1 ++;
            // used as calculating the stuff bits.  
            // counting consequtive 1's. 
        end
        if (bit_to_send == 1'b0) begin
            tb_d_plus = ~tb_d_plus;
            tb_d_minus = ~tb_d_plus; 
            count_1 = 0;
        end
        #(CLK_PERIOD * 8);
        // staff bits. 
        if (count_1 == 6) begin
            count_1 = 0; 
            tb_d_plus =  ~tb_d_plus;
            tb_d_minus = ~tb_d_plus;
            #(CLK_PERIOD * 8);   
            bit_num ++;  
        end
    end
    endtask

    task send_byte(
        input logic [7:0] byte_to_send
    );
    integer i; 
    begin
        bit_num = 0; 
        @(posedge tb_clk); 
        for (i = 0; i < 8; i++) begin
            send_bit(byte_to_send[i]); 
        end
    end 
    endtask

    task send_sync_byte();begin
        send_byte(8'h80); 
    end
    endtask

    task  send_eop();begin
        @(negedge tb_clk); 
        tb_d_plus = 1'b0; 
        tb_d_minus = 1'b0;
        #(CLK_PERIOD * 4); 
    end
    endtask
    
    task  send_PID(
        input logic [3:0] PID_to_send
    );begin
        send_byte({~PID_to_send, PID_to_send});
    end
    endtask

    task  check_fifo(
        input logic [7:0] expected_r_data
    ); begin
        @(negedge tb_clk);
        tb_r_enable = 1;
        @(posedge tb_clk); 
        @(negedge tb_clk)
        if (tb_r_data == expected_r_data) begin
            $info("correct rdata in testcase %d", test_num);
        end
        else $error("incorrect rdata in testcase %d", test_num); 
        @(negedge tb_clk); 
        tb_r_enable = 0;
        #(CLK_PERIOD);    
    end
    endtask //

    task check_err(
        input logic expected_r_error
    ); begin
        #(CLK_PERIOD * 4);    
        if(tb_r_error == expected_r_error) begin
            $info("correct error output in testcase %d", test_num);
        end 
        else $error("incorrect error output in testcase %d.", test_num);
    end
    endtask

    task check_PID(
        input logic[3:0] expected_PID
    ); begin
        #(CLK_PERIOD * 2); // wait for processing. 
        if(tb_PID == expected_PID) begin
            $info("correct PID in testcase %d. ", test_num);
        end 
        else $error("incorrect PID in testcase %d. ", test_num);
    end
    endtask
      
      

    usb11 DUT (
        .clk(tb_clk),
        .n_rst(tb_n_rst),
        .d_plus(tb_d_plus),
        .d_minus(tb_d_minus),
        .r_enable(tb_r_enable),
        .r_data(tb_r_data),
        .empty(tb_empty),
        .full(tb_full),
        .rcving(tb_rcving),
        .r_error(tb_r_error),
        .PID(tb_PID)
    );   

    initial begin
        tb_n_rst = 1;
        tb_d_plus = 1;
        tb_d_minus = 0;
        tb_r_enable = 0;

        tb_expected_PID = '1; 
        
        count_1 = 0;
        test_num = 0;
        bit_num = 0;
        // test case 1
        test_num ++; 
        test_info = "reset DUT"; 
        reset(); 
        check_PID(4'b1111); 
        check_err(1'b0); 
        
        // testcase 2 sync byte transfer. 
        test_num ++; 
        test_info = "sync byte transfer"; 
        reset(); 
        send_sync_byte();
        check_err(1'b0);

        // testcase 3: data byte transfer. 
        test_num ++; 
        test_info = "single byte transfer"; 
        reset(); 
        send_sync_byte();
        send_PID(4'b0001); 
        check_PID(4'b0001); 
        tb_test_byte = 8'b11001001; 
        send_byte(tb_test_byte); 
        check_fifo(tb_test_byte); 
        check_err(1'b0); 
        send_eop(); 


        // testcase 4: bit stuff  test. 
        test_num ++; 
        test_info = "bit stuff  test"; 
        reset(); 
        send_sync_byte();
        send_PID(4'b0001); 
        check_PID(4'b0001); 
        tb_test_byte = 8'b00111111; 
        send_byte(tb_test_byte); 
        check_fifo(tb_test_byte); 
        check_err(1'b0); 
        send_eop(); 
        reset(); 
        send_sync_byte();
        send_PID(4'b0001); 
        check_PID(4'b0001); 
        tb_test_byte = 8'b11111111; 
        send_byte(tb_test_byte); 
        check_fifo(tb_test_byte); 
        check_err(1'b0); 
        send_eop(); 


        // testcase 5: sync error test. 
        test_num ++; 
        test_info = "sync error test"; 
        reset(); 
        send_byte(8'b0);
        check_err(1'b1);  

        // testcase 6: EOP error test. 
        test_num ++; 
        test_info = "sync error test"; 
        reset();
        send_sync_byte();
        send_PID(4'b0001); 
        send_bit(0); 
        send_bit(0); 
        send_eop(); 
        check_err(1'b1);




    end
    
endmodule: tb_usb11
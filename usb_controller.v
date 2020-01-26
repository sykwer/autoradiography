module UsbController(
           clk, reset, data_yaxis, data_xaxis, start_sending,
           read_index_yaxis, read_index_xaxis, command,
           CLK, TXE_N, RXF_N, OE_N, RD_N, WR_N, DATA, BE,
       );
// Command enum
localparam COMMAND_NOOP = 0;

// Mode enum for clk cycle
localparam MODE_WAIT_START_SENDING_UP = 0;
localparam MODE_RECEIVING_DATA = 1;
localparam MODE_RECEIVED_DATA = 2;
localparam MODE_DATA_READY = 3;
localparam MODE_WAIT_START_SENDING_DOWN = 4;

// Mode enum for CLK cycle
localparam MODE_IDLE = 0;
localparam MODE_WILL_OE_N_DOWN = 1;
localparam MODE_WILL_RD_N_DOWN = 2;
localparam MODE_READING_DATA = 3;
localparam MODE_NOTIFY_COMMAND = 4;
localparam MODE_SENDING_DATA = 5;
localparam MODE_SENT_DATA = 6;

input clk, reset, start_sending;
input [15:0] data_yaxis, data_xaxis;

input CLK, TXE_N, RXF_N;
output reg OE_N, RD_N, WR_N;
inout [15:0] DATA;
inout [1:0] BE;

reg [6:0] read_index;
output reg [15:0] command; // default: COMMAND_NOOP

reg [2:0] mode_clk_cycle;
reg [2:0] mode_CLK_cycle;

reg [15:0] read_buffer;
reg [15:0] write_buffer;
reg [7:0] send_data_index;
reg [15:0] data_buffer_yaxis [0:127];
reg [15:0] data_buffer_xaxis [0:127];

reg finish_send_data;

output [6:0] read_index_yaxis, read_index_xaxis;
wire data_ready;

integer i;
always @(posedge clk) begin
    if (reset) begin
        OE_N <= 1; // Write mode by default
        RD_N <= 1;
        WR_N <= 1;
        read_index <= 0;
        command <= COMMAND_NOOP;
        mode_clk_cycle <= MODE_WAIT_START_SENDING_UP;
        mode_CLK_cycle <= MODE_IDLE;
        read_buffer <= 0;
        write_buffer <= 0;
        send_data_index <= 0;

        for (i = 0; i < 128; i = i + 1) begin
            data_buffer_yaxis[i] <= 0;
            data_buffer_xaxis[i] <= 0;
        end

        finish_send_data <= 0;
    end else begin
        if (mode_clk_cycle == MODE_WAIT_START_SENDING_UP) begin
            if (start_sending) begin
                mode_clk_cycle <= MODE_RECEIVING_DATA;
                read_index <= 127;
            end
        end

        if (mode_clk_cycle == MODE_RECEIVING_DATA) begin
            data_buffer_yaxis[read_index] <= data_yaxis;
            data_buffer_xaxis[read_index] <= data_xaxis;
            if (read_index >= 1) begin
                read_index <= read_index - 1;
            end else begin
                mode_clk_cycle <= MODE_RECEIVED_DATA;
                finish_send_data <= 0;
            end
        end

        if (mode_clk_cycle == MODE_RECEIVED_DATA) begin
            mode_clk_cycle <= MODE_DATA_READY;
        end

        if (mode_clk_cycle == MODE_DATA_READY) begin
            if (finish_send_data) begin
                mode_clk_cycle <= MODE_WAIT_START_SENDING_DOWN;
            end
        end

        if (mode_clk_cycle == MODE_WAIT_START_SENDING_DOWN) begin
            if (!start_sending) begin
                mode_clk_cycle <= MODE_WAIT_START_SENDING_UP;
            end
        end
    end
end

// Read command data from client PC on CLK posedge
always @(posedge CLK) begin
    if (mode_CLK_cycle == MODE_READING_DATA) begin
        read_buffer <= DATA;
        mode_CLK_cycle <= MODE_NOTIFY_COMMAND;
    end
end

always @(negedge CLK) begin
    if (mode_CLK_cycle == MODE_IDLE) begin
        if (RXF_N == 0) begin
            mode_CLK_cycle <= MODE_WILL_OE_N_DOWN;
        end else if (data_ready) begin
            WR_N <= 0;
            send_data_index <= 254; // index in the next cycle
            write_buffer <= data_buffer_yaxis[127]; // 255 - 128
            mode_CLK_cycle <= MODE_SENDING_DATA;
        end
    end

    // Read cycle from here
    if (mode_CLK_cycle == MODE_WILL_OE_N_DOWN) begin
        OE_N <= 0;
        mode_CLK_cycle <= MODE_WILL_RD_N_DOWN;
    end

    if (mode_CLK_cycle == MODE_WILL_RD_N_DOWN) begin
        RD_N <= 0;
        mode_CLK_cycle <= MODE_READING_DATA;
    end

    if (mode_CLK_cycle == MODE_NOTIFY_COMMAND) begin
        OE_N <= 1;
        RD_N <= 1;
        command <= read_buffer;
        mode_CLK_cycle <= MODE_IDLE;
    end
    // Read cycle to here

    // Write cycle from here
    if (mode_CLK_cycle == MODE_SENDING_DATA) begin
        if (send_data_index >= 128) begin
            write_buffer <= data_buffer_yaxis[send_data_index - 128];
            send_data_index <= send_data_index - 1;
        end else if (send_data_index >= 1) begin
            write_buffer <= data_buffer_xaxis[send_data_index];
            send_data_index <= send_data_index - 1;
        end else begin
            write_buffer <= data_buffer_xaxis[send_data_index];
            mode_CLK_cycle <= MODE_SENT_DATA;
        end
    end

    if (mode_CLK_cycle == MODE_SENT_DATA) begin
        WR_N <= 1;
        finish_send_data <= 1;
        mode_CLK_cycle <= MODE_IDLE;
    end
    // Write cycle to here
end

assign DATA = !OE_N ? write_buffer : 16'bZ;
assign BE = !OE_N ? 2'b11 : 2'bZ;
assign read_index_yaxis = read_index;
assign read_index_xaxis = read_index;
assign data_ready = (mode_clk_cycle == MODE_DATA_READY);
endmodule

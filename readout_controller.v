module ReadoutController(
           clk, reset, running, integration_clock_count_input, start_adc1, start_adc2, start_adc3, start_adc4,
           INTG, IRST, SHS, SHR, STI, CLK,
       );
// Suppose system clock is 125MHz, which is 8.06451612903..ns/cycle.
// TODO: Change this value according to the frequency of the occilator used.
localparam integer FREQUENCY_MHZ = 125;
localparam integer NS_PER_CYCLE = (1000 + FREQUENCY_MHZ - 1) / FREQUENCY_MHZ;
// Below we define timing restriction in the number of the clock cycle.
//
// t1 (IRST, SHR, SHS, STI high duration) >= 30ns
localparam integer T1 = (30 + NS_PER_CYCLE - 1) / NS_PER_CYCLE;
// t2 (Setup time, STI, IRST falling edge to first clock rising edge) >= 30ns
localparam integer T2 = (30 + NS_PER_CYCLE - 1) / NS_PER_CYCLE;
// t3 (Delay time, 133rd clock rising edge to SHR rising edge) >= 400ns
localparam integer T3 = (400 + NS_PER_CYCLE - 1) / NS_PER_CYCLE;
// t4 (Delay time, SHR rising edge to INTG rising edge) >= 30ns
localparam integer T4 = (30 + NS_PER_CYCLE - 1) / NS_PER_CYCLE;
// t5 (INTG high duration) >= 14us
// Get integration duration as configuration parameter from the host PC.
// t6 (Delay time, INTG falling edge to SHS rising edge) >= 4.5us
localparam integer T6 = (4500 + NS_PER_CYCLE - 1) / NS_PER_CYCLE;
// t7 (Delay time, SHS rising edge to IRST rising edge) >= 30ns
localparam integer T7 = (30 + NS_PER_CYCLE - 1) / NS_PER_CYCLE;
// t8 (Delay time, SHS rising edge to STI rising edge) >= 30ns
localparam integer T8 = (30 + NS_PER_CYCLE - 1) / NS_PER_CYCLE;
// t9 (Hold time, STI falling edge to IRST falling edge) >= 10ns
localparam integer T9 = (10 + NS_PER_CYCLE - 1) / NS_PER_CYCLE;

// CLK clock cycle is restricted to 15MHz at maximum speed.
// On the other hand, the highest conversion frequency of AD7673 is 1.25MSPS
// (800ns/cycle). In sequencial read mode, one adc device receives one integrated
// data per 4 CLK cycles.
// Therefore, the CLK cycle should be longer than 200ns/cycle, which is 5MZ.
// TODO: Change this valud according to the maximum conversion speed of ADC.
// Note that this valud should be lower than or equal to 15MHZ.
localparam real READ_CLK_FREQUENCY_MHZ = 4;
localparam integer READ_CLK_TOGGLE_INTERVAL = (FREQUENCY_MHZ + (2 * READ_CLK_FREQUENCY_MHZ) - 1) / (2 * READ_CLK_FREQUENCY_MHZ);

// Calculate timing constants
localparam START_CLOCK = 0;
localparam STI_DOWN_CLOCK = START_CLOCK + T1;
localparam IRST_DOWN_CLOCK = STI_DOWN_CLOCK + T9;
localparam FIRST_CLK_UP_CLOCK = IRST_DOWN_CLOCK + T2;
localparam LAST_CLK_UP_CLOCK = FIRST_CLK_UP_CLOCK + 132 * 2 * READ_CLK_TOGGLE_INTERVAL;
localparam SHR_UP_CLOCK = LAST_CLK_UP_CLOCK + T3;
localparam SHR_DOWN_CLOCK = SHR_UP_CLOCK + T1;
localparam INTG_UP_CLOCK = SHR_UP_CLOCK + T4;
// Calculate dynamically INTG_DOWN_CLOCK, SHS_UP_CLOCK, SHS_DOWN_CLOCK, END_CLOCK
wire INTG_DOWN_CLOCK, SHS_UP_CLOCK, SHS_DOWN_CLOCK, END_CLOCK;

input clk, reset, running;
input [31:0] integration_clock_count_input;

output reg start_adc1, start_adc2, start_adc3, start_adc4;
output reg INTG, IRST, SHS, SHR, STI, CLK;

reg [31:0] integration_clock_count;
reg [31:0] clock_counter;
reg [31:0] toggle_counter;
reg [31:0] read_data_index;
reg will_start_adc1, will_start_adc2, will_start_adc3, will_start_adc4;

wire [1:0] which_adc;

always @(posedge clk) begin
    if (reset) begin
        start_adc1 <= 0;
        start_adc2 <= 0;
        start_adc3 <= 0;
        start_adc4 <= 0;
        INTG <= 0;
        IRST <= 0;
        SHS <= 0;
        SHR <= 0;
        STI <= 0;
        CLK <= 0;
        integration_clock_count <= 5000; // enough large meaningless number
        clock_counter <= 0;
        toggle_counter <= 0;
        read_data_index <= 0;
        will_start_adc1 <= 0;
        will_start_adc2 <= 0;
        will_start_adc3 <= 0;
        will_start_adc4 <= 0;
    end else begin
        if (running) begin
            if (clock_counter == START_CLOCK) begin
                IRST <= 1;
                STI <= 1;
                integration_clock_count <= integration_clock_count_input;
            end

            if (clock_counter == STI_DOWN_CLOCK) begin
                STI <= 0;
            end

            if (clock_counter == IRST_DOWN_CLOCK) begin
                IRST <= 0;
            end

            // CLK handling - from here
            if (clock_counter == FIRST_CLK_UP_CLOCK) begin
                toggle_counter <= 1;
                CLK <= 1;
            end

            if (clock_counter > FIRST_CLK_UP_CLOCK && clock_counter < LAST_CLK_UP_CLOCK) begin
                if (toggle_counter == READ_CLK_TOGGLE_INTERVAL) begin
                    toggle_counter <= 1;
                    CLK <= !CLK;
                end else begin
                    toggle_counter <= toggle_counter + 1;
                end
            end

            if (clock_counter == LAST_CLK_UP_CLOCK) begin
                CLK <= 1;
            end

            if (clock_counter == LAST_CLK_UP_CLOCK + READ_CLK_TOGGLE_INTERVAL) begin
                CLK <= 0;
            end
            // CLK handling - to here

            // ADC activate - from here
            if (clock_counter == FIRST_CLK_UP_CLOCK) begin
                read_data_index <= 1; // Next data index. 0-indexed.
                will_start_adc2 <= 1;
            end

            if (clock_counter > FIRST_CLK_UP_CLOCK && clock_counter < LAST_CLK_UP_CLOCK) begin
                // CLK posedge && there is still data to be read
                if (toggle_counter == READ_CLK_TOGGLE_INTERVAL && CLK == 0 && read_data_index < 128) begin
                    read_data_index <= read_data_index + 1;

                    if (which_adc == 0) begin
                        will_start_adc2 <= 1;
                    end else if (which_adc == 1) begin
                        will_start_adc4 <= 1;
                    end else if (which_adc == 2) begin
                        will_start_adc1 <= 1;
                    end else begin // which_adc == 3
                        will_start_adc3 <= 1;
                    end
                end
            end

            if (will_start_adc1) begin
                will_start_adc1 <= 0;
                start_adc1 <= 1;
            end else if (will_start_adc2) begin
                will_start_adc2 <= 0;
                start_adc2 <= 1;
            end else if (will_start_adc3) begin
                will_start_adc3 <= 0;
                start_adc3 <= 1;
            end else if (will_start_adc4) begin
                will_start_adc4 <= 0;
                start_adc4 <= 1;
            end

            if (start_adc1 == 1) begin
                start_adc1 <= 0;
            end else if (start_adc2 == 1) begin
                start_adc2 <= 0;
            end else if (start_adc3 == 1) begin
                start_adc3 <= 0;
            end else if (start_adc4 == 1) begin
                start_adc4 <= 0;
            end
            // ADC activate - to here

            if (clock_counter == SHR_UP_CLOCK) begin
                SHR <= 1;
            end

            if (clock_counter == SHR_DOWN_CLOCK) begin
                SHR <= 0;
            end

            if (clock_counter == INTG_UP_CLOCK) begin
                INTG <= 1;
            end

            if (clock_counter == INTG_DOWN_CLOCK) begin
                INTG <= 0;
            end

            if (clock_counter == SHS_UP_CLOCK) begin
                SHS <= 1;
            end

            if (clock_counter == SHS_DOWN_CLOCK) begin
                SHS <= 0;
            end

            if (clock_counter == END_CLOCK) begin
                clock_counter <= START_CLOCK;
            end else begin
                clock_counter <= clock_counter + 1;
            end
        end
    end
end

assign INTG_DOWN_CLOCK = INTG_UP_CLOCK + integration_clock_count;
assign SHS_UP_CLOCK = INTG_DOWN_CLOCK + T6;
assign SHS_DOWN_CLOCK = SHS_UP_CLOCK + T2;
assign END_CLOCK = SHS_DOWN_CLOCK + T7;
assign which_adc = read_data_index % 4;
endmodule

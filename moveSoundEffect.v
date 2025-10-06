module moveSoundEffect (
    input wire clk,            // System clock (e.g., 100 MHz)
    input wire moveSound,      // Goes high for 1 cycle when a move is made
    output reg speaker_out     // Output signal to speaker
);

    // === Configurable Parameters ===
    parameter SOUND_DURATION = 20_000_000; // ~0.2 sec @ 100 MHz
    parameter TONE_PERIOD = 125_000;       // 400 Hz square wave (half period)

    // === Internal Registers ===
    reg [31:0] duration_cnt = 0;
    reg [31:0] tone_cnt = 0;
    reg active = 0;
    reg moveSound_prev = 0;

    wire move_trigger = moveSound && ~moveSound_prev;

    always @(posedge clk) begin
        moveSound_prev <= moveSound;  // latch last value for edge detection

        if (move_trigger) begin
            active <= 1;
            duration_cnt <= 0;
            tone_cnt <= 0;
            speaker_out <= 0;
        end

        if (active) begin
            duration_cnt <= duration_cnt + 1;
            tone_cnt <= tone_cnt + 1;

            if (tone_cnt >= TONE_PERIOD) begin
                speaker_out <= ~speaker_out;
                tone_cnt <= 0;
            end

            if (duration_cnt >= SOUND_DURATION) begin
                active <= 0;
                speaker_out <= 0;
            end
        end else begin
            speaker_out <= 0;
        end
    end

endmodule

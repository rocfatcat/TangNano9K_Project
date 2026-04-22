/**
 * 16-bit Hex to ASCII String Converter
 * ------------------------------------
 * Converts a 16-bit value (e.g., 0xABCD) into a 7-byte ASCII string
 * " [ABCD]\n" for serial output.
 */

module hex_to_ascii (
    input  [15:0] data,
    output [55:0] ascii_str // 7 chars * 8 bits = 56 bits
);

    function [7:0] to_char;
        input [3:0] nibble;
        begin
            if (nibble < 4'hA)
                to_char = 8'h30 + nibble; // '0'-'9'
            else
                to_char = 8'h37 + nibble; // 'A'-'F'
        end
    endfunction

    // Format: " [XXXX]\n"
    assign ascii_str = {
        8'h20,           // ' ' (Space)
        8'h5B,           // '['
        to_char(data[15:12]),
        to_char(data[11:8]),
        to_char(data[7:4]),
        to_char(data[3:0]),
        8'h5D,           // ']'
        8'h0A            // '\n' (Line feed)
    };

endmodule

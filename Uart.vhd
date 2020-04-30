
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_TX is
  generic (
    clockperiods : integer := 217     -- Needs to be set correctly   25Mhz / 115207 = 217 => clock cycles per one bit
    );
  port (
    Clk : in  std_logic;
    Data_valid : in  std_logic; 
    Byte  : in  std_logic_vector(7 downto 0);
    Active : out std_logic;
    Serial : out std_logic;
    oDone   : out std_logic
    );
end UART_TX;


architecture RTL of UART_TX is

  type Main is (Start, Start_Bit, Data_Bits,
                     Stop_Bit, Clear);
  signal sMain : Main := start;

  signal Clk_count : integer range 0 to clockperiods-1 := 0;
  signal Bit_index : integer range 0 to 7 := 0;  -- 8 Bits Total
  signal Data   : std_logic_vector(7 downto 0) := (others => '0');
  signal Done   : std_logic := '0';
  
begin

  
  UART : process (Clk)
  begin
    if rising_edge(Clk) then
        
      case sMain is
		-- setting all the parameters to initial values
        when start =>
          
          Serial <= '1';         
			 Done   <= '0';
          Clk_Count <= 0;
          Bit_Index <= 0;

          if Data_valid = '1' then  -- staying in start state until data_valid = 1
            Data <= Byte;
            sMain <= Start_Bit;
          else
            sMain <= Start;
          end if;

          
        -- Send out Start Bit. Start bit = 0
        when Start_Bit =>
				Active <= '1';
				Serial <= '0';

          -- Wait g_CLKS_PER_BIT-1 clock cycles for start bit to finish
          if Clk_Count < clockperiods-1 then
             Clk_Count <= Clk_Count + 1;
             sMain   <=  Start_Bit;
          else
            Clk_Count <= 0;
            sMain   <= Data_Bits;   --samples data
          end if;

          
        -- Wait g_CLKS_PER_BIT-1 clock cycles for data bits to finish          
        when Data_Bits =>
          Serial <= Data(Bit_Index); -- increasing particular index bit serial byte
          
          if Clk_Count < clockperiods-1 then
             Clk_Count <= Clk_Count + 1;
				 sMain   <= Data_Bits;
          else
            Clk_Count <= 0;
            
            -- checking if we sent all bit 
            if Bit_Index < 7 then
               Bit_Index <= Bit_Index + 1;
               sMain   <= Data_Bits;
            else
              Bit_Index <= 0;
              sMain <= Stop_Bit;
            end if;
          end if;


       -- stop bit process
        when Stop_Bit =>
				Serial <= '1';

          
          if Clk_Count < clockperiods-1 then
            Clk_Count <= Clk_Count + 1;
            sMain   <= Stop_Bit;
          else
            Done   <= '1';
            Clk_Count <= 0;
            sMain   <= clear;
          end if;

                  
        -- Stay here 1 clock
        when clear =>
          Active <= '0';
         
          sMain   <= start;
          
            
        when others =>
          sMain <= start;

      end case;
    end if;
  end process UART;

  oDone <= Done;
  
end RTL;

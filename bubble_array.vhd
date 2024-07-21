----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/23/2021 05:13:38 PM
-- Design Name: 
-- Module Name: bubble_array - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity bubble_array is
    Generic (n: natural := 32;
             k: natural := 5);
    Port ( d_in     : in std_logic_vector(n-1 downto 0);
           d_out    : out std_logic_vector(n-1 downto 0);
           scan_en  : in std_logic;
           run_en   : in std_logic;
           reset    : in std_logic;
           ck       : in std_logic);
end bubble_array;

architecture Behavioral of bubble_array is
component pe 
  Generic (n : natural := 32);
  Port ( li     : in std_logic_vector(n-1 downto 0);
         ri     : in std_logic_vector(n-1 downto 0);
         lo     : out std_logic_vector(n-1 downto 0);
         ro     : out std_logic_vector(n-1 downto 0);
         ck     : in std_logic;
         reset  : in std_logic;
         scan_en: in std_logic;
         run_en : in std_logic;
         pe_type: in std_logic
  );
end component;

type vector_array is array (natural range<>) of std_logic_vector(n-1 downto 0);
signal w_L  : vector_array(0 to k);
signal w_R  : vector_array(0 to k-1); 
signal odd  : std_logic;
signal even : std_logic;
signal minus_inf, inf, w_in     : std_logic_vector(n-1 downto 0);

begin

    minus_inf   <= (n-1 => '1', others => '0');
    inf         <= (n-1 => '0', others => '1');
    odd         <= '1';
    even        <= '0';
    
    process(scan_en, d_in)
    begin
        if scan_en = '1' then
            w_in    <= d_in;
        else
            w_in    <= minus_inf;
        end if;    
    end process;
    
    w_L(0)      <=  w_in;
    w_R(k-1)    <=  inf;
    d_out       <=  w_L(k);
    
    G1: for i in 0 to k-1 generate
        G_input:    if i = 0 generate
            A:  pe 
                  Generic map (n)
                  Port    map( li       =>  w_L(i),
                               ri       =>  w_R(i),
                               lo       =>  w_L(i+1),
                               ro       =>  open,
                               ck       =>  ck,
                               reset    =>  reset,
                               scan_en  =>  scan_en,
                               run_en   =>  run_en,
                               pe_type  =>  even
                      );
        end generate G_input;
        G_even:    if i mod 2 = 0 and i > 0 generate
                                  A:  pe 
                                        Generic map (n)
                                        Port    map( li       =>  w_L(i),
                                                     ri       =>  w_R(i),
                                                     lo       =>  w_L(i+1),
                                                     ro       =>  w_R(i-1),
                                                     ck       =>  ck,
                                                     reset    =>  reset,
                                                     scan_en  =>  scan_en,
                                                     run_en   =>  run_en,
                                                     pe_type  =>  even
                                            );
        end generate G_even;                                            
        G_odd:    if i mod 2 = 1 and i > 0 generate
                                      A:  pe 
                                            Generic map (n)
                                            Port    map( li       =>  w_L(i),
                                                         ri       =>  w_R(i),
                                                         lo       =>  w_L(i+1),
                                                         ro       =>  w_R(i-1),
                                                         ck       =>  ck,
                                                         reset    =>  reset,
                                                         scan_en  =>  scan_en,
                                                         run_en   =>  run_en,
                                                         pe_type  =>  odd
                                                );
        end generate G_odd;
    end generate G1;                                                
end Behavioral;











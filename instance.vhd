----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/23/2021 06:34:04 PM
-- Design Name: 
-- Module Name: instance - Behavioral
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

entity instance is
    Generic ( n :   natural := 32;
              k :   natural := 5);
    Port    ( d_in          :   in std_logic_vector(n-1 downto 0);
              d_out         :   out std_logic_vector(n-1 downto 0);
              reset         :   in std_logic;
              go            :   in std_logic;
              bus2ip_w_ack  :   in std_logic;
              bus2ip_r_ack  :   in std_logic;
              ck            :   in std_logic;
              new_data      :   out std_logic; 
              done          :   out std_logic );
end instance;

architecture Structural of instance is
signal scan_en              : std_logic;
signal run_en               : std_logic;
signal reset_array          : std_logic;

type    device_operating_state     is  (idle, wait_on_go_low, download, reset_device, run, wait_done_ack, wait_on_done_ack_low, upload, chill);
type    download_handshake_state   is  (ready_for_new_data, consume, wait_for_w_ack_low);
type    upload_handshake_state     is  (new_data_is_ready, put_new_data, wait_for_r_ack_low);
subtype my_integer                 is  integer range 0 to k;

signal  device_state            :   device_operating_state;
signal  download_sync_state     :   download_handshake_state;
signal  upload_sync_state       :   upload_handshake_state;
signal  count                   :   my_integer;

component bubble_array is
    Generic (n: natural := 32;
             k: natural := 5);
    Port ( d_in     : in std_logic_vector(n-1 downto 0);
           d_out    : out std_logic_vector(n-1 downto 0);
           scan_en  : in std_logic;
           run_en   : in std_logic;
           reset    : in std_logic;
           ck       : in std_logic);
end component;

begin

    U2  :   bubble_array 
            Generic map(n => n,
                        k => k)
            Port map( d_in     =>   d_in,
                      d_out    =>   d_out,
                      scan_en  =>   scan_en,
                      run_en   =>   run_en,
                      reset    =>   reset_array,
                      ck       =>   ck);

    process(ck)
    begin
        if ck = '1' and ck'event then
            if reset = '1' then
                device_state    <=  idle;
            else
                case device_state is
                    when    idle    =>
                        download_sync_state     <=  ready_for_new_data;
                        upload_sync_state       <=  new_data_is_ready;
                        count                   <=  0;
                        new_data                <= '0';
                        scan_en                 <= '0';
                        run_en                  <= '0';
                        reset_array             <= '1';
                        done                    <= '0';
                        if  go = '1' then
                            device_state        <=  wait_on_go_low;
                        end if;
                    when    wait_on_go_low    =>
                        new_data                <= '0';
                        scan_en                 <= '0';
                        run_en                  <= '0';
                        reset_array             <= '0';
                        done                    <= '0';
                        if  go = '0' then
                            device_state        <=  download;
                        end if;
                    when    download    =>
                        case    download_sync_state is
                            when    ready_for_new_data  =>
                                new_data                <= '1';
                                scan_en                 <= '0';
                                run_en                  <= '0';
                                reset_array             <= '0';
                                done                    <= '0';
                                if  bus2ip_w_ack = '1' then
                                    download_sync_state <=  consume;
                                end if;
                            when    consume     =>
                                new_data                <= '0';
                                scan_en                 <= '1';
                                run_en                  <= '0';
                                reset_array             <= '0';
                                done                    <= '0';
                                download_sync_state     <=  wait_for_w_ack_low;
                                count                   <=  count + 1;
                            when    wait_for_w_ack_low     =>
                                new_data                <= '0';
                                scan_en                 <= '0';
                                run_en                  <= '0';
                                reset_array             <= '0';
                                done                    <= '0';
                                if  bus2ip_w_ack = '0' then
                                    download_sync_state <=  ready_for_new_data;
                                end if;    
                                if  count = k then
                                    device_state        <=  reset_device;
                                end if;
                        end case;
                    when    reset_device    =>
                        new_data                <= '0';
                        scan_en                 <= '0';
                        run_en                  <= '1';
                        reset_array             <= '1';
                        done                    <= '0';
                        device_state            <= run;
                        count                   <= 0;
                    when    run             =>
                        new_data                <= '0';
                        scan_en                 <= '0';
                        run_en                  <= '1';
                        reset_array             <= '0';
                        if count < k then
                            count               <=  count + 1;
                            done                <=  '0';
                        else
                            device_state        <=  wait_done_ack;
                            count               <=  0;
                            done                <=  '1';
                        end if;            
                    when    wait_done_ack   =>
                        new_data                <= '0';
                        scan_en                 <= '0';
                        run_en                  <= '0';
                        reset_array             <= '0';
                        if go = '1' then
                            device_state        <=  wait_on_done_ack_low;
                            done                <=  '0';
                        else
                            done                <=  '1';
                        end if;
                    when    wait_on_done_ack_low    =>
                        new_data                <= '0';
                        scan_en                 <= '0';
                        run_en                  <= '1';
                        reset_array             <= '1';
                        done                    <= '0';
                        if go = '0' then
                            device_state        <= upload;
                        end if;
                    when    upload      =>
                        case    upload_sync_state is
                            when    new_data_is_ready   =>
                                new_data                <= '1';
                                scan_en                 <= '0';
                                run_en                  <= '0';
                                reset_array             <= '0';
                                done                    <= '0';
                                if bus2ip_r_ack = '1' then
                                    upload_sync_state   <= put_new_data;
                                    count               <= count + 1;
                                end if;
                            when    put_new_data   =>
                                new_data                <= '0';
                                scan_en                 <= '1';
                                run_en                  <= '0';
                                reset_array             <= '0';
                                done                    <= '0';
                                upload_sync_state       <= wait_for_r_ack_low;
                            when    wait_for_r_ack_low  =>
                                new_data                <= '0';
                                scan_en                 <= '0';
                                run_en                  <= '0';
                                reset_array             <= '0';
                                done                    <= '0';
                                if bus2ip_r_ack = '0' then
                                    upload_sync_state   <= new_data_is_ready;
                                end if;
                                if count = k then
                                    device_state        <= chill;
                                end if;
                        end case;
                    when    chill   =>
                        new_data                <= '0';
                        scan_en                 <= '0';
                        run_en                  <= '0';
                        reset_array             <= '0';
                        done                    <= '1';
                end case;
            end if;
        end if;
    end process;    
end Structural;














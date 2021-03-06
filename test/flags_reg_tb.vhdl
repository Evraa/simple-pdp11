library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity flags_reg_tb is
    generic (runner_cfg: string);
end entity; 

architecture tb of flags_reg_tb is
    constant CLK_FREQ: integer := 100e6; -- 100 MHz
    constant CLK_PERD: time    := 1000 ms / CLK_FREQ;

    signal clk: std_logic := '0';

    constant WORD_WIDTH : integer := 16;

    -- ordinary reg
    signal data_in: std_logic_vector(WORD_WIDTH-1 downto 0);
    signal enable_in, enable_out: std_logic;
    signal data_out: std_logic_vector(WORD_WIDTH-1 downto 0);

    -- flags additional ports
    signal from_alu: std_logic_vector(5-1 downto 0);
    signal enable_from_alu: std_logic;
    signal always_out: std_logic_vector(5-1 downto 0);
    signal clr_carry, set_carry: std_logic;
begin
    clk <= not clk after CLK_PERD / 2;

    flags_reg: entity work.flags_reg port map (
        data_in => data_in,
        enable_in => enable_in,
        enable_out => enable_out,
        clk => clk,
        data_out => data_out,
        from_alu => from_alu,
        enable_from_alu => enable_from_alu,
        always_out => always_out,
        clr_carry => clr_carry,
        set_carry => set_carry
    );

    main: process
    begin
        test_runner_setup(runner, runner_cfg);
        set_stop_level(failure);

        data_in <= (others => '0');
        enable_in <= '0';
        from_alu <= (others => '0');
        enable_from_alu <= '0';

        if run("always_out") then
            enable_in <= '1';
            data_in(5-1 downto 0) <= "01011";
            wait for CLK_PERD;
            enable_in <= '0';

            enable_out <= '1';
            wait for CLK_PERD;
            check_equal(always_out, to_vec("01011", 5));

            enable_out <= '0';
            wait for CLK_PERD;
            check_equal(always_out, to_vec("01011", 5));

            enable_out <= '0';
            wait for CLK_PERD;
            check_equal(always_out, to_vec("01011", 5));
        end if;

        if run("from_alu") then
            enable_in <= '1';
            data_in(5-1 downto 0) <= "01011";
            wait for CLK_PERD;
            enable_in <= '0';

            from_alu <= (others => '1');
            enable_from_alu <= '1';
            wait for 2*CLK_PERD;
            enable_from_alu <= '0';
            check_equal(always_out, to_vec('1', 5));

            enable_out <= '1';
            wait for 2*CLK_PERD;
            enable_out <= '0';
            check_equal(data_out, to_vec('0', 16-5) & to_vec('1', 5));
        end if;

        if run("carry") then
            set_carry <= '1';
            wait for CLK_PERD;
            check_equal(always_out(0), '1');
            set_carry <= '0';

            clr_carry <= '1';
            wait for CLK_PERD;
            check_equal(always_out(0), '0');
            clr_carry <= '0';
        end if;

        wait for CLK_PERD/2;
        test_runner_cleanup(runner);
        wait;
    end process;
end architecture;

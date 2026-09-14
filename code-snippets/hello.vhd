-- VHDL
entity hello is
end entity;

architecture sim of hello is
begin
  process
  begin
    report "Hello, World!";
    wait;
  end process;
end architecture;

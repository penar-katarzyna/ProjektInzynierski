LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY AES_decrypt IS
PORT(
	CLK		: IN STD_LOGIC
);
END AES_decrypt;

ARCHITECTURE behavior of AES_decrypt IS

BEGIN

PROCESS 
BEGIN
WAIT UNTIL(CLK'EVENT) AND (CLK = '1');
END PROCESS;

END behavior;
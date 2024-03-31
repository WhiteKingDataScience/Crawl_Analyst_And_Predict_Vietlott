USE vietlott
GO
---- Create schema
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'power')
EXEC('CREATE SCHEMA power')


--- Create table draw_result_power
IF NOT EXISTS (
				SELECT * FROM information_schema.tables 
				WHERE table_schema = 'power' 
				AND table_name = 'draw_result_power'
			  )
CREATE TABLE power.draw_result_power (
    draw_ID INT PRIMARY KEY,
	draw_date DATE,
    ball_1 VARCHAR(2),
    ball_2 VARCHAR(2),
	ball_3 VARCHAR(2),
	ball_4 VARCHAR(2),
	ball_5 VARCHAR(2),
	ball_6 VARCHAR(2),
	ball_special VARCHAR(2)
);
IF NOT EXISTS (
				SELECT * FROM sys.indexes
				WHERE object_id = OBJECT_ID('vietlott.power.draw_result_power')
				AND name = 'idx_draw_date'
			)
BEGIN
CREATE INDEX idx_draw_date ON power.draw_result_power(draw_date);
END

---CREATE table  prize_result_power
IF NOT EXISTS (
				SELECT * FROM information_schema.tables 
				WHERE table_schema = 'power' 
				AND table_name = 'prize_result_power'
				)
CREATE TABLE power.prize_result_power (
    prize VARCHAR(50),
    number_of_prizes INT,
    prize_value BIGINT,
    draw_ID INT,
    draw_date DATE,
	winning_condition VARCHAR(200)
);

IF NOT EXISTS (
				SELECT * FROM sys.indexes
				WHERE object_id = OBJECT_ID('vietlott.power.prize_result_power')
				AND name in ('idx_draw_date', 'idx_draw_id')
			)
BEGIN
CREATE INDEX idx_draw_date ON power.prize_result_power(draw_date)
CREATE INDEX idx_draw_id ON power.prize_result_power(draw_ID)
END
GO

--- Tạo trigger để tự động cập nhật cột winning_condition

CREATE OR ALTER TRIGGER power.Set_Winning_Condition_Power ON power.prize_result_power
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE p
    SET p.winning_condition = CASE
        WHEN i.prize = 'Jackpot 1' THEN 'Match 6 numbers with the results of ball_1, ball_2, ball_3, ball_4, ball_5, and ball_6'
        WHEN i.prize = 'Jackpot 2' THEN 'Match 5 numbers among the results of ball_1, ball_2, ball_3, ball_4, ball_5, ball_6, and also match with ball_special'
        WHEN i.prize = 'First prize' THEN 'Match 5 numbers among the results of ball_1, ball_2, ball_3, ball_4, ball_5, ball_6'
        WHEN i.prize = 'Second prize' THEN 'Match 4 numbers among the results of ball_1, ball_2, ball_3, ball_4, ball_5, ball_6'
        ELSE 'Match 3 numbers among the results of ball_1, ball_2, ball_3, ball_4, ball_5, ball_6'
    END
    FROM vietlott.power.prize_result_power p
    INNER JOIN inserted i ON p.draw_ID = i.draw_ID AND p.prize = i.prize;
END;

ALTER TABLE power.prize_result_power ENABLE TRIGGER  Set_Winning_Condition_Power
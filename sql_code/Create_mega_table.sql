USE vietlott
GO
---- Create schema
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'mega')
EXEC('CREATE SCHEMA mega')

--- Create table draw_result_mega
IF NOT EXISTS (SELECT * 
				FROM information_schema.tables 
				WHERE table_schema = 'mega' 
				AND table_name = 'draw_result_mega')
CREATE TABLE mega.draw_result_mega (
    draw_ID INT PRIMARY KEY,
	draw_date DATE,
    ball_1 VARCHAR(2),
    ball_2 VARCHAR(2),
	ball_3 VARCHAR(2),
	ball_4 VARCHAR(2),
	ball_5 VARCHAR(2),
	ball_6 VARCHAR(2)
);

IF NOT EXISTS (
				SELECT * FROM sys.indexes
				WHERE object_id = OBJECT_ID('vietlott.mega.draw_result_mega')
				AND name = 'idx_draw_date'
			)
BEGIN
CREATE INDEX idx_draw_date ON mega.draw_result_mega(draw_date);
END

---CREATE table  prize_result_mega
IF NOT EXISTS (SELECT * 
				FROM information_schema.tables 
				WHERE table_schema = 'mega' 
				AND table_name = 'prize_result_mega')
CREATE TABLE mega.prize_result_mega (
    prize VARCHAR(50),
    number_of_prizes INT,
    prize_value BIGINT,
    draw_ID INT,
    draw_date DATE,
	winning_condition VARCHAR(200)
);

IF NOT EXISTS (
				SELECT * FROM sys.indexes
				WHERE object_id = OBJECT_ID('vietlott.mega.prize_result_mega')
				AND name in ('idx_draw_date', 'idx_draw_id')
			)
BEGIN
CREATE INDEX idx_draw_date ON mega.prize_result_mega(draw_date)
CREATE INDEX idx_draw_id ON mega.prize_result_mega(draw_ID)
END
GO


CREATE OR ALTER TRIGGER mega.Set_Winning_Condition_Mega ON vietlott.mega.prize_result_mega
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE p
    SET p.winning_condition = CASE
        WHEN i.prize = 'Jackpot' THEN 'Match 6 numbers with the results of ball_1, ball_2, ball_3, ball_4, ball_5, and ball_6'
        WHEN i.prize = 'First prize' THEN 'Match 5 numbers among the results of ball_1, ball_2, ball_3, ball_4, ball_5, ball_6'
        WHEN i.prize = 'Second prize' THEN 'Match 4 numbers among the results of ball_1, ball_2, ball_3, ball_4, ball_5, ball_6'
        ELSE 'Match 3 numbers among the results of ball_1, ball_2, ball_3, ball_4, ball_5, ball_6'
    END
    FROM vietlott.mega.prize_result_mega p
    INNER JOIN inserted i ON p.draw_ID = i.draw_ID AND p.prize = i.prize;
END;

ALTER TABLE mega.prize_result_mega ENABLE TRIGGER  Set_Winning_Condition_Mega
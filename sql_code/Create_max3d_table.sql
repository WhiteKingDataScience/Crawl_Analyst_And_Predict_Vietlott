USE vietlott
GO
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'max3d')
EXEC('CREATE SCHEMA max3d')


IF NOT EXISTS (
				SELECT * FROM information_schema.tables 
				WHERE table_schema = 'max3d' 
				AND table_name = 'prize_result_max3d'
			  )
---CREATE table  prize_result_max3d
CREATE TABLE max3d.prize_result_max3d (
    draw_ID INT,
    draw_date DATE,
    prize VARCHAR(50),
    number_of_prizes INT,
    prize_value BIGINT,
	result_1 VARCHAR(3),
	result_2 VARCHAR(3),
	result_3 VARCHAR(3),
	result_4 VARCHAR(3),
	result_5 VARCHAR(3),
	result_6 VARCHAR(3),
	result_7 VARCHAR(3),
	result_8 VARCHAR(3),
	winning_condition VARCHAR(200)
);

IF NOT EXISTS (
				SELECT * FROM sys.indexes
				WHERE object_id = OBJECT_ID('vietlott.max3d.prize_result_max3d')
				AND name in ('idx_draw_date', 'idx_draw_id')
			)
BEGIN
CREATE INDEX idx_draw_date ON max3d.prize_result_max3d(draw_date)
CREATE INDEX idx_draw_id ON max3d.prize_result_max3d(draw_ID)
END
GO


CREATE OR ALTER TRIGGER max3d.Set_Winning_Condition_Max3D ON max3d.prize_result_max3d
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE p
    SET p.winning_condition = CASE
        WHEN i.prize = 'Special Prize' THEN 'Match any 1 sets of 3 numbers out of 2 sets'
		WHEN i.prize = 'First prize' THEN 'Match any 1 set of 3 numbers out of 4 sets'
        WHEN i.prize = 'Second prize' THEN 'Match any 1 set of 3 numbers out of 6 sets'
        ELSE 'Match any 1 set of 3 numbers out of 8 sets'
    END
    FROM vietlott.max3d.prize_result_max3d p
    INNER JOIN inserted i ON p.draw_ID = i.draw_ID AND p.prize = i.prize;
END;


ALTER TABLE max3d.prize_result_max3d ENABLE TRIGGER  Set_Winning_Condition_Max3D
-- Performance benchmarking query example

-- Measure the average response time for various operations on Posts and related entities

-- Temporary table to capture timing data
CREATE TEMPORARY TABLE BenchmarkResults (Operation VARCHAR(100), DurationMs INT);

-- Benchmarking: Inserting data into Posts
BEGIN;
DECLARE @StartTime INT = DATEDIFF(MILLISECOND, '1970-01-01', GETDATE());
INSERT INTO Posts (PostTypeId, CreationDate, Score, ViewCount, Body, OwnerUserId, Title)
SELECT TOP 1000 1, GETDATE(), 0, 0, 'Sample Post Body', Id, 'Sample Title' FROM Users;
DECLARE @EndTime INT = DATEDIFF(MILLISECOND, '1970-01-01', GETDATE());
INSERT INTO BenchmarkResults (Operation, DurationMs) VALUES ('Insert Posts', @EndTime - @StartTime);
COMMIT;

-- Benchmarking: Selecting Posts with JOIN on Users
BEGIN;
SET @StartTime = DATEDIFF(MILLISECOND, '1970-01-01', GETDATE());
SELECT p.Id, p.Title, u.DisplayName
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
WHERE p.PostTypeId = 1; -- Selecting only Questions
SET @EndTime = DATEDIFF(MILLISECOND, '1970-01-01', GETDATE());
INSERT INTO BenchmarkResults (Operation, DurationMs) VALUES ('Select Posts with Users', @EndTime - @StartTime);
COMMIT;

-- Benchmarking: Counting Posts per User
BEGIN;
SET @StartTime = DATEDIFF(MILLISECOND, '1970-01-01', GETDATE());
SELECT u.Id, COUNT(p.Id) AS PostCount
FROM Users u
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
GROUP BY u.Id;
SET @EndTime = DATEDIFF(MILLISECOND, '1970-01-01', GETDATE());
INSERT INTO BenchmarkResults (Operation, DurationMs) VALUES ('Count Posts per User', @EndTime - @StartTime);
COMMIT;

-- Benchmarking: Aggregating Votes on Posts
BEGIN;
SET @StartTime = DATEDIFF(MILLISECOND, '1970-01-01', GETDATE());
SELECT p.Id, SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
              SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM Posts p
LEFT JOIN Votes v ON p.Id = v.PostId
GROUP BY p.Id;
SET @EndTime = DATEDIFF(MILLISECOND, '1970-01-01', GETDATE());
INSERT INTO BenchmarkResults (Operation, DurationMs) VALUES ('Aggregate Votes on Posts', @EndTime - @StartTime);
COMMIT;

-- Retrieve benchmarking results
SELECT * FROM BenchmarkResults;

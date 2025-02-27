BEGIN;

-- Create a temporary table to store benchmarking results
CREATE TEMP TABLE BenchmarkResults (
    QueryName VARCHAR(255),
    ExecutionTime INTERVAL,
    RowCount INT
);

-- Benchmark 1: Count total posts
EXPLAIN ANALYZE
INSERT INTO BenchmarkResults (QueryName, ExecutionTime, RowCount)
SELECT 'Total Posts', pg_sleep(0), COUNT(*)
FROM Posts;

-- Benchmark 2: Get the most recent posts
EXPLAIN ANALYZE
INSERT INTO BenchmarkResults (QueryName, ExecutionTime, RowCount)
SELECT 'Recent Posts', pg_sleep(0), COUNT(*)
FROM Posts
ORDER BY CreationDate DESC
LIMIT 100;

-- Benchmark 3: Count users with at least one post
EXPLAIN ANALYZE
INSERT INTO BenchmarkResults (QueryName, ExecutionTime, RowCount)
SELECT 'Users with Posts', pg_sleep(0), COUNT(DISTINCT OwnerUserId)
FROM Posts;

-- Benchmark 4: Count votes on posts
EXPLAIN ANALYZE
INSERT INTO BenchmarkResults (QueryName, ExecutionTime, RowCount)
SELECT 'Total Votes', pg_sleep(0), COUNT(*)
FROM Votes;

-- Benchmark 5: Get all post types with counts
EXPLAIN ANALYZE
INSERT INTO BenchmarkResults (QueryName, ExecutionTime, RowCount)
SELECT 'Post Types Count', pg_sleep(0), COUNT(*)
FROM PostTypes;

-- Display Benchmark Results
SELECT * FROM BenchmarkResults;

DROP TABLE BenchmarkResults;

COMMIT;

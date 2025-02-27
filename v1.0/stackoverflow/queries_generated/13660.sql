-- Performance Benchmarking Query
-- This query benchmarks the performance of inserting a large number of posts with associated user data and relevant attributes.

WITH RECURSIVE PostGenerator AS (
    SELECT 1 AS PostId, 
           1 AS PostTypeId, 
           NOW() AS CreationDate, 
           'Sample Title ' || 1 AS Title, 
           'Sample Body for post number ' || 1 AS Body, 
           0 AS Score, 
           'tag1,tag2' AS Tags,
           0 AS AnswerCount,
           0 AS CommentCount,
           0 AS FavoriteCount
    UNION ALL
    SELECT PostId + 1, 
           PostTypeId, 
           NOW(), 
           'Sample Title ' || (PostId + 1), 
           'Sample Body for post number ' || (PostId + 1), 
           Score, 
           Tags,
           AnswerCount,
           CommentCount,
           FavoriteCount
    FROM PostGenerator
    WHERE PostId < 10000  -- Adjust this number for larger or smaller batch size
)

INSERT INTO Posts (Id, PostTypeId, CreationDate, Title, Body, Score, Tags, AnswerCount, CommentCount, FavoriteCount)
SELECT PostId, PostTypeId, CreationDate, Title, Body, Score, Tags, AnswerCount, CommentCount, FavoriteCount
FROM PostGenerator;

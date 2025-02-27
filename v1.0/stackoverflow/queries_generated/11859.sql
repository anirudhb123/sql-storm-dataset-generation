-- Performance Benchmarking Query

-- This query benchmarks the performance of retrieving posts with their associated user details and post history.
-- It selects various columns from the Posts table, along with user details from the Users table 
-- and the latest history of the posts from the PostHistory table.

WITH LatestPostHistory AS (
    SELECT 
        Ph.PostId,
        Ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY Ph.PostId ORDER BY Ph.CreationDate DESC) AS rn
    FROM 
        PostHistory Ph
)

SELECT 
    P.Id AS PostId,
    P.Title,
    P.Body,
    P.CreationDate AS PostCreationDate,
    U.DisplayName AS AuthorDisplayName,
    U.Reputation AS AuthorReputation,
    LP.HistoryCreationDate,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount,
    P.FavoriteCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    (SELECT PostId, CreationDate AS HistoryCreationDate FROM LatestPostHistory WHERE rn = 1) LP 
    ON P.Id = LP.PostId
WHERE 
    P.CreationDate > NOW() - INTERVAL '1 year' -- Only consider posts from the last year
ORDER BY 
    P.CreationDate DESC;

-- This query is designed to measure the efficiency of joins and the execution time for fetching the latest post history related to user posts.

-- Performance Benchmarking SQL Query

-- This query retrieves the most popular questions (highest score) along with their details,
-- and joins with related users and vote information to measure the performance of joins
-- and aggregations on the Stack Overflow schema.

SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    p.Score,
    p.CreationDate,
    p.ViewCount,
    COUNT(v.Id) AS VoteCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.PostTypeId = 1  -- Filter for questions
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.Score DESC
LIMIT 100;  -- Limit to top 100 questions

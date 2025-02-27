-- Performance Benchmarking SQL Query

-- This query retrieves a summary of Posts along with associated user and voting information
-- to analyze performance and execution time while accessing multiple tables.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    p.FavoriteCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(DISTINCT v.Id) AS VoteCount,
    STRING_AGG(DISTINCT vt.Name, ', ') AS VoteTypes
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
WHERE 
    p.CreationDate >= '2020-01-01'  -- Filter for posts created in 2020 and later
GROUP BY 
    p.Id, u.DisplayName, u.Reputation
ORDER BY 
    p.CreationDate DESC;  -- Sort by creation date

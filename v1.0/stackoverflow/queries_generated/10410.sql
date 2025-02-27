-- Performance Benchmarking Query

-- This query retrieves a summary of posts along with associated user stats and vote counts,
-- aimed at evaluating the performance of joins and aggregations in the specific schema.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(v.Id) AS VoteCount,
    COUNT(c.Id) AS CommentCount,
    MAX(ph.CreationDate) AS LastHistoryDate
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
GROUP BY 
    p.Id, u.DisplayName, u.Reputation
ORDER BY 
    p.CreationDate DESC
LIMIT 1000;  -- Limit the results for benchmarking purposes

-- Performance Benchmarking Query for StackOverflow Schema

-- This query retrieves a summary of post statistics, user reputation, and vote counts for performance benchmarking.
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    p.FavoriteCount,
    u.Reputation AS OwnerReputation,
    COUNT(v.Id) AS TotalVotes
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    p.Id, u.Reputation
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Adjust the limit as necessary for benchmarking

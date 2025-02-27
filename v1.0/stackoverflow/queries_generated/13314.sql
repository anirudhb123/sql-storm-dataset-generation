-- Performance Benchmarking Query
-- This query retrieves statistics on posts, including the number of answers, comments, views, and upvotes,
-- along with average reputation of the owners of these posts.

SELECT 
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    p.Score,
    COALESCE(u.Reputation, 0) AS OwnerReputation,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COUNT(DISTINCT v.Id) AS TotalVotes
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    p.Id, u.Reputation
ORDER BY 
    p.CreationDate DESC
LIMIT 100;  -- Limiting to the most recent 100 posts for benchmarking

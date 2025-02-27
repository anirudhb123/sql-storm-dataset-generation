-- Performance benchmarking query for the Stack Overflow schema
-- This query retrieves the top posts by score along with associated user data,
-- while also aggregating the number of comments and votes on each post.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score,
    p.CreationDate AS PostCreationDate,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.PostTypeId IN (1, 2) -- Considering only Questions and Answers for benchmarking
GROUP BY 
    p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName, u.Reputation
ORDER BY 
    p.Score DESC
LIMIT 100; -- Limit to the top 100 posts by score for benchmarking

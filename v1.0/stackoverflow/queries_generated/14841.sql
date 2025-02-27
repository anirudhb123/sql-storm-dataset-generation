-- Performance Benchmarking Query for Stack Overflow Schema

-- This query retrieves information about posts, users, votes, and comments
-- to evaluate the performance of joins and aggregations, focusing on active users and top posts.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    u.Reputation > 1000  -- Filtering for active/users with significant reputation
GROUP BY 
    p.Id, p.Title, p.CreationDate, u.DisplayName, u.Reputation
ORDER BY 
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC  -- Order by upvotes
LIMIT 100;  -- Limit to top 100 posts

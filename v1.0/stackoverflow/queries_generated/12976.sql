-- Performance benchmarking query for Stack Overflow schema
-- This query will retrieve statistics about posts, users, and their activity including the count of votes and comments.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score AS PostScore,
    p.ViewCount,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    u.Reputation AS UserReputation,
    u.DisplayName AS UserDisplayName,
    u.CreationDate AS UserCreationDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    p.Id, u.Id
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Limiting to the latest 100 posts for performance assessment

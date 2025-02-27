-- Performance benchmarking query for StackOverflow schema
-- This query fetches a summary of posts, votes, and user information. 
-- It aggregates the data to analyze performance in posts and their engagement metrics.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.ViewCount,
    p.CreationDate,
    u.DisplayName AS OwnerName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    SUM(CASE 
        WHEN v.VoteTypeId = 2 THEN 1 
        ELSE 0 
    END) AS UpVotes,
    SUM(CASE 
        WHEN v.VoteTypeId = 3 THEN 1 
        ELSE 0 
    END) AS DownVotes
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON c.PostId = p.Id
LEFT JOIN 
    Votes v ON v.PostId = p.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '30 days' -- last 30 days
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.ViewCount DESC
LIMIT 100; -- Limit results for performance evaluation

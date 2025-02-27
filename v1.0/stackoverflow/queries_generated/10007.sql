-- Performance benchmarking query for Stack Overflow schema

-- This query retrieves various metrics regarding users, their posts, and the corresponding votes and comments
-- It aims to evaluate the performance based on post creation counts, average vote scores, and comments per post.

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS PostCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(v.VoteTypeId = 2) AS UpVoteCount,  -- Count UpVotes
    SUM(v.VoteTypeId = 3) AS DownVoteCount, -- Count DownVotes
    AVG(p.Score) AS AveragePostScore,
    MAX(p.CreationDate) AS LastPostDate,
    MIN(p.CreationDate) AS FirstPostDate
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    PostCount DESC;

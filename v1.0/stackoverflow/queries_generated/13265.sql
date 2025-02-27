-- Performance Benchmarking Query

-- This query retrieves statistics related to posts, including counts and average scores, 
-- along with details about their creators and the number of votes they received.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.PostTypeId,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COALESCE(SUM(v.vote_count), 0) AS TotalVotes,
    AVG(p.Score) AS AverageScore,
    COUNT(DISTINCT b.Id) AS BadgeCount
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    p.Id, p.Title, p.PostTypeId, u.DisplayName
ORDER BY 
    TotalVotes DESC, AverageScore DESC
LIMIT 
    100;

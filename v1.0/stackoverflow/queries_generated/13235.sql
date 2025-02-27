-- Performance benchmarking query for Stack Overflow schema

-- This query retrieves statistics about users, their posts, comments, and badges while calculating the total scores and activity levels.

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COUNT(DISTINCT b.Id) AS TotalBadges,
    SUM(p.Score) AS TotalPostScore,
    SUM(c.Score) AS TotalCommentScore,
    (COUNT(DISTINCT p.Id) + COUNT(DISTINCT c.Id)) AS TotalActivity,
    MAX(p.CreationDate) AS LastPostDate,
    MAX(c.CreationDate) AS LastCommentDate
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON u.Id = c.UserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    TotalActivity DESC;

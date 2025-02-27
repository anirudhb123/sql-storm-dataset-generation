-- Performance benchmarking query: Retrieve the top users by aggregated score from their posts and their total reputation

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    SUM(COALESCE(p.Score, 0)) AS TotalPostScore,
    SUM(u.Reputation) AS TotalReputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COUNT(DISTINCT ba.Id) AS TotalBadges
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON c.UserId = u.Id
LEFT JOIN 
    Badges ba ON u.Id = ba.UserId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalPostScore DESC
LIMIT 10;

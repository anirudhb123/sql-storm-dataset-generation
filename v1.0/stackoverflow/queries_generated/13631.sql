-- Performance Benchmarking Query

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoredPosts,
    AVG(p.ViewCount) AS AverageViewCount,
    COUNT(DISTINCT p.OwnerUserId) AS UniqueUsers,
    COUNT(c.Id) AS TotalComments,
    SUM(b.Class = 1)::int AS GoldBadges,
    SUM(b.Class = 2)::int AS SilverBadges,
    SUM(b.Class = 3)::int AS BronzeBadges,
    MAX(p.CreationDate) AS LatestPostDate
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Performance Benchmarking Query

-- This query retrieves the number of posts, average score of posts, and average view count, 
-- grouped by post type, along with user reputations and badge counts.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AvgScore,
    AVG(p.ViewCount) AS AvgViewCount,
    SUM(CASE WHEN b.UserId IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges,
    AVG(u.Reputation) AS AvgUserReputation
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON b.UserId = u.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Performance Benchmarking Query
-- This query retrieves the count of posts, average score of those posts, and 
-- the distribution of post types. It also joins the Posts table with Users to get user reputation.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS PostsByUsers,
    SUM(CASE WHEN p.OwnerUserId IS NULL THEN 1 ELSE 0 END) AS CommunityPosts,
    SUM(u.Reputation) AS TotalUserReputation
FROM 
    Posts p
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

-- The above query provides insights into post performance based on post types.
-- This includes the count of each post type, the average score of posts in that type,
-- and statistics on whether the posts are community-owned or user-owned.

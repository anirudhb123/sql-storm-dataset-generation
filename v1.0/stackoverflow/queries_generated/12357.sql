-- Performance Benchmarking Query
-- This query retrieves the number of posts, average score, and total view count per user,
-- as well as a count of badges associated with each user. 
-- It will help in understanding user engagement and content contribution.

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViewCount,
    COUNT(DISTINCT b.Id) AS TotalBadges
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalPosts DESC;

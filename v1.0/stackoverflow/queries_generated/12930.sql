-- Performance Benchmarking Query
-- This query retrieves the number of users, the total number of posts created by each user, and the average view count for their posts.
-- Additionally, it counts the badges per user and calculates the total score for posts associated with each user.

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.ViewCount) AS AverageViewCount,
    COUNT(b.Id) AS TotalBadges,
    SUM(p.Score) AS TotalScore
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalPosts DESC, TotalScore DESC;

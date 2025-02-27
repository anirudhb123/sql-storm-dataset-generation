-- Performance Benchmarking Query

-- This query will gather aggregate statistics on posts, including the number of posts 
-- per user, average score of posts, and average view count of posts.

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalPosts DESC;

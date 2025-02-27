-- Performance benchmarking query for the StackOverflow schema

-- This query retrieves the number of posts per user along with the average score and total view count.
-- It aims to assess the performance of user contributions in terms of activity and engagement.

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(p.Id) AS TotalPosts,
    AVG(COALESCE(p.Score, 0)) AS AverageScore,
    SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalPosts DESC;

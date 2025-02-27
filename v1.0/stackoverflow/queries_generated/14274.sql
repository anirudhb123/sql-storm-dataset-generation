-- Performance Benchmarking Query for StackOverflow Schema
-- This query aims to evaluate the performance of joining multiple tables and aggregating data.

SELECT 
    u.DisplayName AS UserName,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    SUM(v.BountyAmount) AS TotalBountyAmount,
    AVG(u.Reputation) AS AvgUserReputation,
    MAX(p.CreationDate) AS LatestPostDate
FROM 
    Users u
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
WHERE 
    u.Reputation > 1000 -- Filter for users with reputation greater than 1000
GROUP BY 
    u.DisplayName
ORDER BY 
    TotalPosts DESC
LIMIT 100; -- Limit to top 100 users based on total posts

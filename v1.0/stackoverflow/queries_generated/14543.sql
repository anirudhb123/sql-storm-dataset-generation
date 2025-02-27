-- Performance Benchmarking SQL Query

-- This query will aggregate data from multiple tables to evaluate the performance
-- of posts, users, and the relationship between them. It retrieves the total number of posts,
-- users, and their respective scores, while also analyzing the average reputation of users
-- related to their post activity.

SELECT 
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT u.Id) AS TotalUsers,
    SUM(p.Score) AS TotalPostScore,
    AVG(u.Reputation) AS AverageUserReputation,
    COUNT(DISTINCT b.Id) AS TotalBadges,
    COUNT(CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
    COUNT(CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
    COUNT(DISTINCT c.Id) AS TotalComments
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.CreationDate >= DATEADD(MONTH, -6, GETDATE()) -- posts from the last 6 months
GROUP BY 
    u.Reputation
ORDER BY 
    TotalPosts DESC;

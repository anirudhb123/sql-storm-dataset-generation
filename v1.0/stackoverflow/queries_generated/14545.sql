-- Performance Benchmarking Query

-- This query retrieves a list of users along with their post statistics,
-- including the total number of posts, the number of questions, and the number of answers they have contributed.
-- It also calculates the average score of their posts and the total reputation each user has.

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    AVG(p.Score) AS AveragePostScore,
    u.Reputation
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalPosts DESC;

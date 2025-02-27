-- Performance Benchmarking Query
-- This query retrieves the top 10 users by reputation along with their post statistics

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
    COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
    SUM(COALESCE(p.Score, 0)) AS TotalScore,
    SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
    SUM(COALESCE(c.Id, 0)) AS TotalComments
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    u.Reputation > 0 -- Considering only users with positive reputation
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC
LIMIT 10;

-- This query evaluates the performance of retrieving user data along with their associated posts, comments, and reputation.

-- Performance benchmarking query on the Stack Overflow schema

-- This query retrieves the number of posts created by each user along with their total score,
-- average reputation, and the most recent activity date.
-- It helps to evaluate the user engagement and quality of contributions.

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(p.Id) AS TotalPosts,
    SUM(p.Score) AS TotalScore,
    AVG(u.Reputation) AS AverageReputation,
    MAX(p.LastActivityDate) AS MostRecentActivity
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalPosts DESC;

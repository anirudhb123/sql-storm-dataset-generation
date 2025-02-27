-- Performance benchmarking query to evaluate the most active users, the number of posts they have created,
-- and the average score of their posts, as well as their reputation and most recent activity.

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AveragePostScore,
    u.Reputation,
    MAX(p.LastActivityDate) AS MostRecentActivity
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    TotalPosts DESC, AveragePostScore DESC;

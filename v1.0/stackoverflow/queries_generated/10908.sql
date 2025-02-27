-- Performance Benchmarking Query

-- This query fetches the total number of posts, average score, and user reputation
-- for users who have created posts, while measuring the join performance among
-- Posts, Users, and Votes tables.

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(p.Id) AS TotalPosts,
    COALESCE(AVG(p.Score), 0) AS AverageScore,
    u.Reputation
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    TotalPosts DESC, AverageScore DESC;

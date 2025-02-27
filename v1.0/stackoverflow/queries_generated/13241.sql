-- Performance benchmarking query for StackOverflow schema

-- This query retrieves the count of posts, average score, and average view count per post type,
-- along with the total number of users and average reputation. 
-- It uses GROUP BY to aggregate results by post type.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount,
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    AVG(u.Reputation) AS AverageReputation
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    pt.Id, pt.Name
ORDER BY 
    TotalPosts DESC;

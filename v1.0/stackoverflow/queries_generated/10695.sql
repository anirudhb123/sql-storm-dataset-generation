-- Performance benchmarking query for StackOverflow schema

-- This query retrieves the number of posts, average score, and total views grouped by post type,
-- along with user details like reputation and account creation date.
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews,
    u.Reputation AS UserReputation,
    u.CreationDate AS UserCreationDate
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    pt.Name, u.Reputation, u.CreationDate
ORDER BY 
    TotalPosts DESC;

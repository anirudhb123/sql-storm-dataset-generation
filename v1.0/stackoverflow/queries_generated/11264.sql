-- Performance benchmarking query to analyze the number of posts, their types, and the associated users

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS TotalOwnedPosts,
    COUNT(DISTINCT p.OwnerUserId) AS UniqueUsers,
    AVG(u.Reputation) AS AverageUserReputation
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Additional indexing may be required for better performance, depending on the size of the data.

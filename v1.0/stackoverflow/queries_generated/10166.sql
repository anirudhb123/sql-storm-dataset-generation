-- Performance Benchmarking Query for StackOverflow Schema

-- This query retrieves the count of posts, average score, and view count, 
-- grouped by post types, along with user reputation and creation date for user level insights.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AvgScore,
    AVG(p.ViewCount) AS AvgViewCount,
    u.Reputation AS UserReputation,
    u.CreationDate AS UserCreationDate
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    pt.Name, u.Reputation, u.CreationDate
ORDER BY 
    TotalPosts DESC, AvgScore DESC;

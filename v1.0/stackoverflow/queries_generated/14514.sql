-- Performance benchmarking query: Retrieve statistics about posts, including the number of posts per type,
-- average score, and total view count grouped by post type and user reputation.

SELECT 
    pt.Name AS PostType,
    u.Reputation AS UserReputation,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViewCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    pt.Name, u.Reputation
ORDER BY 
    pt.Name, u.Reputation;

-- Performance Benchmarking Query

-- This query retrieves the count of posts, average score, and total view count 
-- per post type and joins with users to get the reputation of the post owners 
-- to analyze performance based on post engagement and owner reputation.

SELECT 
    pt.Name AS PostType, 
    COUNT(p.Id) AS PostCount, 
    AVG(p.Score) AS AvgScore, 
    SUM(p.ViewCount) AS TotalViews,
    AVG(u.Reputation) AS AvgOwnerReputation
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

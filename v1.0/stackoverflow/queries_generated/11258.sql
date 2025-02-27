-- Performance Benchmarking Query

-- This query retrieves the count of posts, average score, and average view count 
-- for each post type along with the user reputation of the post owner and their display name.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AvgScore,
    AVG(p.ViewCount) AS AvgViewCount,
    AVG(u.Reputation) AS AvgUserReputation,
    STRING_AGG(DISTINCT u.DisplayName, ', ') AS UserNames
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '30 days' -- Filtering for recent posts
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

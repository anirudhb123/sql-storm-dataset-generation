-- Performance Benchmarking Query

-- This query compares the number of posts, average view count, and average score
-- grouped by post type while also filtering out closed and deleted posts.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.ViewCount) AS AvgViewCount,
    AVG(p.Score) AS AvgScore
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.ClosedDate IS NULL AND 
    p.AcceptedAnswerId IS NOT NULL  -- Assuming we want only posts that are answered
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

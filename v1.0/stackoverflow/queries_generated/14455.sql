-- Performance Benchmarking Query

-- This query retrieves the count of posts, average scores, and average view counts
-- grouped by post types, along with the total number of votes associated with these posts.
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AvgScore,
    AVG(p.ViewCount) AS AvgViewCount,
    COALESCE(SUM(CASE WHEN v.PostId IS NOT NULL THEN 1 ELSE 0 END), 0) AS TotalVotes
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

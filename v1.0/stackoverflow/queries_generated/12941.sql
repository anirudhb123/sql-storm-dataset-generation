-- Performance benchmarking query for StackOverflow Schema

-- This query retrieves the total number of posts, the average score of posts,
-- the average view count, and the total number of unique users who have made posts
-- The results are grouped by post type, along with a count of different post history types.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount,
    COUNT(DISTINCT p.OwnerUserId) AS UniqueUsers,
    COUNT(DISTINCT ph.PostHistoryTypeId) AS UniquePostHistoryTypes
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

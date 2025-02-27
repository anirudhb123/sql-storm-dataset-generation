-- Performance benchmarking query for StackOverflow schema
-- This query retrieves various statistics including total posts, 
-- average views per post, average score, and count of users and tags.

SELECT 
    COUNT(DISTINCT p.Id) AS TotalPosts,
    AVG(p.ViewCount) AS AverageViewsPerPost,
    AVG(p.Score) AS AverageScore,
    COUNT(DISTINCT u.Id) AS TotalUsers,
    COUNT(DISTINCT t.Id) AS TotalTags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Tags t ON t.ExcerptPostId = p.Id OR t.WikiPostId = p.Id
WHERE 
    p.CreationDate >= '2023-01-01' -- Filtering posts created in 2023
    AND p.PostTypeId = 1; -- Only count questions


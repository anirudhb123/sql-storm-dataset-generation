-- Performance Benchmarking Query

-- This query retrieves detailed statistics about posts, along with their owners, comments, and the number of votes.
-- We will group the results by post type to understand the distribution and engagement across different types of posts.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
    SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativeScorePosts,
    SUM(p.ViewCount) AS TotalViews,
    AVG(p.ViewCount) AS AvgViewsPerPost,
    MAX(p.ViewCount) AS MaxViewsPerPost,
    COUNT(c.Id) AS TotalComments,
    COUNT(v.Id) AS TotalVotes,
    COUNT(DISTINCT u.Id) AS UniqueUsers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= DATEADD(year, -1, GETDATE()) -- considering only posts from the last year
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

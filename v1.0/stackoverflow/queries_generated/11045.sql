-- Performance Benchmarking SQL Query

-- This query retrieves statistics about posts, their types, and associated user engagement metrics

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    SUM(p.ViewCount) AS TotalViews,
    SUM(p.Score) AS TotalScore,
    AVG(p.Score) AS AverageScore,
    AVG(EXTRACT(EPOCH FROM (p.LastActivityDate - p.CreationDate)) / 3600) AS AverageHoursToActivity,
    COUNT(DISTINCT c.Id) AS TotalComments,
    SUM(v.VoteTypeId = 2) AS TotalUpvotes, -- Assuming 2 is the UpMod vote type
    SUM(v.VoteTypeId = 3) AS TotalDownvotes -- Assuming 3 is the DownMod vote type
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '30 days' -- Filter for the last 30 days
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Performance Benchmarking Query

-- This query retrieves metrics for the different post types including counts, scores, and user activity within a defined time frame.
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    COALESCE(SUM(p.Score), 0) AS TotalScore,
    COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    COALESCE(SUM(b.Count), 0) AS TotalTags
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    (SELECT 
         Id, COUNT(*) AS Count 
     FROM 
         Tags 
     GROUP BY 
         Id) b ON p.Tags LIKE '%' || b.TagName || '%'
WHERE 
    p.CreationDate >= NOW() - INTERVAL '30 days'  -- Adjust the time frame as necessary
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

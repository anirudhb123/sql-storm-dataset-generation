WITH RECURSIVE TagHierarchy AS (
    SELECT 
        t.Id,
        t.TagName,
        t.Count,
        ARRAY[t.TagName] AS Path
    FROM 
        Tags t
    WHERE 
        t.IsRequired = 1
        
    UNION ALL
    
    SELECT 
        t.Id,
        t.TagName,
        t.Count,
        Path || t.TagName
    FROM 
        Tags t
    JOIN 
        PostLinks pl ON pl.RelatedPostId = t.Id
    JOIN 
        TagHierarchy th ON pl.PostId = th.Id
)
SELECT 
    th.Path,
    COUNT(DISTINCT p.Id) AS PostCount,
    SUM(p.ViewCount) AS TotalViews,
    AVG(p.Score) AS AvgScore,
    STRING_AGG(DISTINCT u.DisplayName, ', ') AS UserContributors
FROM 
    TagHierarchy th
JOIN 
    Posts p ON p.Tags LIKE '%' || th.TagName || '%'
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    th.Path
ORDER BY 
    PostCount DESC 
LIMIT 10;

-- This query benchmarks string processing by analyzing tags in the tag hierarchy 
-- and their corresponding posts while aggregating statistics related to view counts, scores, 
-- and the contributors to those posts. The use of recursive CTE allows for handling 
-- complex tag relationships, if such relationships exist.

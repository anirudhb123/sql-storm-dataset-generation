-- Performance benchmarking query for StackOverflow schema
-- This query retrieves statistics about posts, including the count of posts, average score, and the most recent edit date, grouped by post type.

SELECT 
    pt.Name AS PostType, 
    COUNT(p.Id) AS PostCount, 
    AVG(p.Score) AS AverageScore, 
    MAX(p.LastEditDate) AS MostRecentEditDate
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.CreationDate >= '2023-01-01'  -- Consider posts created in the current year
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

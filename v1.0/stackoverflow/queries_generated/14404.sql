-- Performance Benchmarking SQL Query
-- This query will measure the performance of SELECTing distinct tags and counting related posts.

WITH TagPostCounts AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.Id = p.ExcerptPostId OR t.Id = p.WikiPostId
    GROUP BY 
        t.TagName
)
SELECT 
    TagName, 
    PostCount
FROM 
    TagPostCounts
ORDER BY 
    PostCount DESC;

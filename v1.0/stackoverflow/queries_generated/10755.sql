-- Performance Benchmarking Query

-- This query retrieves the count of posts by type, along with the average score and average view count for each post type.
-- This can help assess the distribution of post types and their engagement metrics.

SELECT
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount
FROM
    Posts p
JOIN
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY
    pt.Name
ORDER BY
    PostCount DESC;

-- Performance Benchmarking Query
-- This query retrieves the number of posts, average score, and total view count
-- for each post type, along with the most recent activity date.

SELECT
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViewCount,
    MAX(p.LastActivityDate) AS MostRecentActivity
FROM
    Posts p
JOIN
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY
    pt.Name
ORDER BY
    PostCount DESC;

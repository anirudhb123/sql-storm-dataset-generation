-- Performance Benchmarking Query for StackOverflow Schema

-- This query retrieves the number of posts by post type along with average score and view count
-- to assess the performance of various post types on the platform.

SELECT
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount
FROM
    Posts p
JOIN
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY
    pt.Name
ORDER BY
    TotalPosts DESC;

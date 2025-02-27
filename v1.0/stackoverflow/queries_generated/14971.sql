-- Performance benchmarking query to analyze the number of posts and their related metrics
SELECT
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.ViewCount) AS AverageViewCount,
    AVG(p.Score) AS AverageScore,
    SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS TotalAcceptedAnswers,
    SUM(CASE WHEN p.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS TotalClosedPosts,
    AVG(
        SELECT COUNT(c.Id)
        FROM Comments c
        WHERE c.PostId = p.Id
    ) AS AverageCommentsPerPost
FROM
    Posts p
JOIN
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY
    pt.Name
ORDER BY
    TotalPosts DESC;

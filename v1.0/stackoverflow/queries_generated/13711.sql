-- Performance benchmarking query to evaluate the average view count, score, and answer count of posts by post type

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.ViewCount) AS AverageViewCount,
    AVG(p.Score) AS AverageScore,
    AVG(p.AnswerCount) AS AverageAnswerCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

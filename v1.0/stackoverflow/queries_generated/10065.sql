-- Performance benchmarking query to analyze the number of posts by post type and their average scores

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS NumberOfPosts,
    AVG(p.Score) AS AverageScore
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    NumberOfPosts DESC;

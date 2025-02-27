
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    COUNT(c.Id) AS TotalComments
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.CreationDate >= DATEADD(day, -30, CAST('2024-10-01 12:34:56' AS DATETIME))
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

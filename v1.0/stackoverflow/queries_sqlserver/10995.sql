
SELECT 
    pt.Name AS PostType,
    COUNT(c.Id) AS CommentCount,
    AVG(p.Score) AS AverageScore,
    AVG(DATEDIFF(MINUTE, p.CreationDate, '2024-10-01 12:34:56')) AS AverageResponseTimeInMinutes
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
GROUP BY 
    pt.Name
ORDER BY 
    CommentCount DESC, AverageScore DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

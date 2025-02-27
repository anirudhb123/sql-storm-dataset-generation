
SELECT 
    pt.Name AS PostType, 
    COUNT(p.Id) AS TotalPosts, 
    AVG(DATEDIFF(SECOND, p.CreationDate, p.LastActivityDate)) AS AvgTimeToActivity
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

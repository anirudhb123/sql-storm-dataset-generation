
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount,
    AVG(p.AnswerCount) AS AverageAnswerCount,
    MAX(p.LastActivityDate) AS MostRecentActivity,
    AVG(TIMESTAMPDIFF(SECOND, p.CreationDate, p.LastActivityDate)) AS AverageTimeToActivity 
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;


SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews,
    COUNT(DISTINCT p.OwnerUserId) AS UniqueAuthors,
    SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
    MAX(p.LastActivityDate) AS MostRecentActivity
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name, p.Id, p.Score, p.ViewCount, p.OwnerUserId, p.AcceptedAnswerId, p.LastActivityDate
ORDER BY 
    TotalPosts DESC;

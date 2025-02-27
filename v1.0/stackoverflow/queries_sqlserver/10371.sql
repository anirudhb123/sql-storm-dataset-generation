
SELECT 
    u.Id AS UserId,
    u.DisplayName AS UserName,
    u.Reputation,
    COUNT(p.Id) AS TotalPosts,
    COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
    COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
    SUM(ISNULL(p.Score, 0)) AS TotalScore,
    SUM(ISNULL(p.ViewCount, 0)) AS TotalViews,
    AVG(ISNULL(p.Score, 0)) AS AverageScore,
    AVG(ISNULL(p.ViewCount, 0)) AS AverageViews
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    TotalPosts DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;

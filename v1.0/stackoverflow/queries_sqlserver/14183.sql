
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
    COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
    SUM(ISNULL(p.Score, 0)) AS TotalScore,
    SUM(ISNULL(p.ViewCount, 0)) AS TotalViews,
    SUM(ISNULL(c.Id, 0)) AS TotalComments
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    u.Reputation > 0 
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;


SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    SUM(ISNULL(p.Score, 0)) AS TotalScore
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC
OFFSET 0 ROWS 
FETCH NEXT 10 ROWS ONLY;

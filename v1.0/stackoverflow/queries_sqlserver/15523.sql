
SELECT 
    u.DisplayName AS UserName,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    AVG(u.Reputation) AS AvgReputation
FROM 
    Users AS u
LEFT JOIN 
    Posts AS p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    TotalPosts DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

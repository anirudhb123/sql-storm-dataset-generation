
SELECT 
    p.OwnerUserId,
    COUNT(p.Id) AS TotalPosts,
    u.Reputation
FROM 
    Posts AS p
JOIN 
    Users AS u ON p.OwnerUserId = u.Id
GROUP BY 
    p.OwnerUserId, u.Reputation
ORDER BY 
    TotalPosts DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;

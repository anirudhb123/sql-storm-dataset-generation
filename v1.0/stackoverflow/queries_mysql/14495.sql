
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(b.Id) AS BadgeCount,
    AVG(TIMESTAMPDIFF(SECOND, u.CreationDate, CURRENT_TIMESTAMP) / 60) AS AverageAccountAgeInMinutes
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    u.Reputation > 100
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC;

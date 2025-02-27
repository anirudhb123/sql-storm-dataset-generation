
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AvgScore,
    AVG(p.ViewCount) AS AvgViewCount,
    AVG(u.Reputation) AS AvgUserReputation,
    GROUP_CONCAT(DISTINCT u.DisplayName ORDER BY u.DisplayName SEPARATOR ', ') AS UserNames
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 30 DAY
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

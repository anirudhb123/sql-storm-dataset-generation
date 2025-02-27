
SELECT 
    pt.Name AS PostType, 
    COUNT(p.Id) AS PostCount, 
    AVG(p.Score) AS AverageScore, 
    AVG(p.ViewCount) AS AverageViewCount,
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT COUNT(*) FROM Badges) AS TotalBadges
FROM 
    Posts AS p
JOIN 
    PostTypes AS pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

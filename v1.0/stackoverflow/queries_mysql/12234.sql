
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    COUNT(DISTINCT u.Id) AS UserCount,
    AVG(u.Reputation) AS AvgReputation,
    SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
    SUM(p.ViewCount) AS TotalViewCount,
    SUM(p.Score) AS TotalScore,
    MAX(p.CreationDate) AS LatestPostDate
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    pt.Name, p.Id, u.Id, u.Reputation, p.AcceptedAnswerId, p.ViewCount, p.Score, p.CreationDate
ORDER BY 
    PostCount DESC;

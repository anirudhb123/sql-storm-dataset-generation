
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AvgScore,
    SUM(CASE WHEN vt.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN vt.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
    SUM(CASE WHEN vt.VoteTypeId = 10 THEN 1 ELSE 0 END) AS TotalCloseVotes,
    SUM(CASE WHEN vt.VoteTypeId = 11 THEN 1 ELSE 0 END) AS TotalReopenVotes
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Votes vt ON p.Id = vt.PostId
WHERE 
    p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0)  
GROUP BY 
    pt.Name, p.Score
ORDER BY 
    PostCount DESC;

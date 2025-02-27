
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    IFNULL(pv.TotalVotes, 0) AS TotalVotes,
    IFNULL(ph.RevisionCount, 0) AS RevisionCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT 
        PostId,
        COUNT(*) AS TotalVotes
     FROM 
        Votes
     GROUP BY 
        PostId) pv ON p.Id = pv.PostId
LEFT JOIN 
    (SELECT 
        PostId,
        COUNT(*) AS RevisionCount
     FROM 
        PostHistory
     GROUP BY 
        PostId) ph ON p.Id = ph.PostId
WHERE 
    p.CreationDate >= DATE_SUB('2024-10-01 12:34:56', INTERVAL 1 MONTH)
ORDER BY 
    p.Score DESC
LIMIT 100;


SELECT 
    ph.PostId,
    COUNT(*) AS RevisionCount,
    MIN(ph.CreationDate) AS FirstRevisionDate,
    MAX(ph.CreationDate) AS LastRevisionDate,
    DATEDIFF('second', MIN(ph.CreationDate), MAX(ph.CreationDate)) AS TotalRevisionTime
FROM 
    PostHistory ph
GROUP BY 
    ph.PostId
ORDER BY 
    RevisionCount DESC;

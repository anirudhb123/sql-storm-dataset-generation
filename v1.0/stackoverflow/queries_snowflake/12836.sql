
SELECT 
    ph.PostHistoryTypeId, 
    COUNT(*) AS RevisionCount, 
    MIN(ph.CreationDate) AS FirstRevisionDate, 
    MAX(ph.CreationDate) AS LastRevisionDate, 
    AVG(DATEDIFF(SECOND, ph.CreationDate, COALESCE(ph2.CreationDate, CURRENT_TIMESTAMP))) AS AvgTimeBetweenRevisions
FROM 
    PostHistory ph
LEFT JOIN 
    PostHistory ph2 ON ph.PostId = ph2.PostId AND ph.CreationDate < ph2.CreationDate
GROUP BY 
    ph.PostHistoryTypeId
ORDER BY 
    RevisionCount DESC;

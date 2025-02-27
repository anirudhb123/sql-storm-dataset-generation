
SELECT 
    ph.PostHistoryTypeId,
    COUNT(*) AS BenchmarkCount,
    MIN(ph.CreationDate) AS EarliestChange,
    MAX(ph.CreationDate) AS LatestChange
FROM 
    PostHistory ph
JOIN 
    Posts p ON ph.PostId = p.Id
WHERE 
    p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
GROUP BY 
    ph.PostHistoryTypeId, ph.CreationDate
ORDER BY 
    BenchmarkCount DESC;

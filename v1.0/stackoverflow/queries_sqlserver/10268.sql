
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
    p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0)
GROUP BY 
    ph.PostHistoryTypeId
ORDER BY 
    BenchmarkCount DESC;

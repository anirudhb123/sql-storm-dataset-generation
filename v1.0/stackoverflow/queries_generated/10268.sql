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
    p.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY 
    ph.PostHistoryTypeId
ORDER BY 
    BenchmarkCount DESC;

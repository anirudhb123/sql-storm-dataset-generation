SELECT 
    ph.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    ph.PostHistoryTypeId,
    ph.CreationDate AS HistoryDate,
    u.DisplayName AS EditorDisplayName
FROM 
    PostHistory ph
JOIN 
    Posts p ON ph.PostId = p.Id
JOIN 
    Users u ON ph.UserId = u.Id
WHERE 
    ph.CreationDate > NOW() - INTERVAL '1 year'  -- Filter for the last year
ORDER BY 
    ph.CreationDate DESC
LIMIT 100;  -- Limiting results for performance benchmarking

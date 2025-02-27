
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
    ph.CreationDate > '2023-10-01 12:34:56'  
ORDER BY 
    ph.CreationDate DESC
LIMIT 100;


SELECT 
    ph.PostId,
    p.Title,
    ph.PostHistoryTypeId,
    p.CreationDate,
    ph.CreationDate AS RevisionDate,
    u.DisplayName AS EditedByUser,
    ph.Comment,
    ph.Text
FROM 
    PostHistory ph
JOIN 
    Posts p ON ph.PostId = p.Id
JOIN 
    Users u ON ph.UserId = u.Id
WHERE 
    ph.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME2) - INTERVAL '30 days' 
ORDER BY 
    ph.CreationDate DESC;

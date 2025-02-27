
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
    ph.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 30 DAY
GROUP BY 
    ph.PostId,
    p.Title,
    ph.PostHistoryTypeId,
    p.CreationDate,
    RevisionDate,
    EditedByUser,
    ph.Comment,
    ph.Text
ORDER BY 
    ph.CreationDate DESC;

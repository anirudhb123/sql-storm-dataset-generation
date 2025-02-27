-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    ph.PostHistoryTypeId,
    ph.CreationDate AS HistoryCreationDate,
    ph.UserDisplayName AS EditorDisplayName
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'
ORDER BY 
    p.CreationDate DESC
LIMIT 100;

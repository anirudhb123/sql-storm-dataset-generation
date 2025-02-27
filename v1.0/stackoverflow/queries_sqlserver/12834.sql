
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
    p.CreationDate >= CAST('2024-10-01 12:34:56' AS datetime) - INTERVAL '1 year'
GROUP BY 
    p.Id,
    p.Title,
    u.DisplayName,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    ph.PostHistoryTypeId,
    ph.CreationDate,
    ph.UserDisplayName
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;

SELECT 
    u.DisplayName AS UserName,
    p.Title AS PostTitle,
    ph.CreationDate AS HistoryDate,
    p.Body AS PostBody,
    ph.Comment AS EditComment
FROM 
    Posts p
JOIN 
    PostHistory ph ON p.Id = ph.PostId
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1  -- This filters only Questions
ORDER BY 
    ph.CreationDate DESC
LIMIT 10;

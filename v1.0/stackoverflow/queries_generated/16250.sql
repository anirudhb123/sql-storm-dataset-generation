SELECT 
    p.Title,
    p.CreationDate,
    u.DisplayName as OwnerDisplayName,
    p.Score,
    p.ViewCount,
    ct.Name as CloseReason
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11) -- 10 = Post Closed, 11 = Post Reopened
LEFT JOIN 
    CloseReasonTypes ct ON ph.Comment::int = ct.Id
WHERE 
    p.PostTypeId = 1 -- Only Questions
ORDER BY 
    p.CreationDate DESC
LIMIT 10;

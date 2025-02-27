
SELECT 
    p.Title,
    u.DisplayName AS Owner,
    p.CreationDate,
    p.Score,
    ct.Name AS CloseReason
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
LEFT JOIN 
    CloseReasonTypes ct ON CAST(ph.Comment AS SIGNED) = ct.Id
WHERE 
    p.PostTypeId = 1
GROUP BY 
    p.Title, u.DisplayName, p.CreationDate, p.Score, ct.Name
ORDER BY 
    p.CreationDate DESC
LIMIT 10;

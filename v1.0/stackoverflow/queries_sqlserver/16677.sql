
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    ct.Name AS CloseReason
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10 
LEFT JOIN 
    CloseReasonTypes ct ON CAST(ph.Comment AS INT) = ct.Id
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Id, p.Title, p.CreationDate, u.DisplayName, ct.Name
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

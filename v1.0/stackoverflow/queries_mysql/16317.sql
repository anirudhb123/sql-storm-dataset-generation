
SELECT 
    u.DisplayName AS UserDisplayName,
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    ph.CreationDate AS HistoryCreationDate,
    p.Tags AS PostTags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    ph.PostHistoryTypeId IN (4, 5)
GROUP BY 
    u.DisplayName, p.Title, p.CreationDate, ph.CreationDate, p.Tags
ORDER BY 
    ph.CreationDate DESC
LIMIT 100;

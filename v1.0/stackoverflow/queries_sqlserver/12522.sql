
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    ph.CreationDate AS PostHistoryDate,
    ph.Comment AS PostHistoryComment,
    v.CreationDate AS VoteCreationDate,
    vt.Name AS VoteTypeName
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
WHERE 
    u.Reputation > 1000 
GROUP BY 
    u.Id, u.DisplayName, p.Id, p.Title, p.CreationDate, ph.CreationDate, ph.Comment, v.CreationDate, vt.Name
ORDER BY 
    u.Id, p.Id, ph.CreationDate DESC;

-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    u.DisplayName AS OwnerDisplayName,
    COUNT(v.Id) AS VoteCount,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
    COUNT(c.Id) AS CommentCount,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    pt.Name AS PostTypeName,
    ph.CreationDate AS LastEditDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
GROUP BY 
    p.Id, u.DisplayName, pt.Name, ph.CreationDate
ORDER BY 
    VoteCount DESC, PostCreationDate DESC;

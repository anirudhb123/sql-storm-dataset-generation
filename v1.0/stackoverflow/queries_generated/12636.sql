SELECT 
    p.Title AS PostTitle,
    u.DisplayName AS Author,
    p.CreationDate AS PostCreationDate,
    COUNT(c.Id) AS CommentCount,
    MAX(v.CreationDate) AS LastVoteDate,
    SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVoteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '30 days'
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    PostCreationDate DESC;

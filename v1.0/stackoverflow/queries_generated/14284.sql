-- Performance Benchmarking SQL Query
SELECT 
    p.Id AS PostId, 
    p.Title, 
    p.CreationDate, 
    p.ViewCount, 
    p.Score, 
    u.DisplayName AS OwnerDisplayName, 
    COUNT(c.Id) AS CommentCount, 
    COUNT(v.Id) AS VoteCount,
    SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC;

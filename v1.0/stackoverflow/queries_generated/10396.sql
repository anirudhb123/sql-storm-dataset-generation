-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes,
    SUM(CASE WHEN vt.Name = 'Favorite' THEN 1 ELSE 0 END) AS FavoriteCount,
    STRING_AGG(t.TagName, ', ') AS Tags
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
LEFT JOIN 
    (SELECT 
         pt.Id, 
         t.TagName 
     FROM 
         Posts pt 
     JOIN 
         STRING_SPLIT(pt.Tags, '<>') AS tag ON pt.Id = t.Id) t ON p.Id = t.Id
WHERE 
    p.PostTypeId = 1 -- Selecting only questions
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Limit can be adjusted for benchmarking

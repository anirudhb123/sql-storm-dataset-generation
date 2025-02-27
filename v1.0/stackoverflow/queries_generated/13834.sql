-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    COUNT(distinct c.Id) AS CommentCount,
    COUNT(distinct a.Id) AS AnswerCount,
    SUM(v.VoteTypeId = 2) AS UpVotes,
    SUM(v.VoteTypeId = 3) AS DownVotes,
    ph.CreationDate AS LastEditDate,
    u.DisplayName AS OwnerDisplayName
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1  -- Only considering Questions
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, ph.CreationDate, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 100;

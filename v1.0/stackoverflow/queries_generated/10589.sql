-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score,
    p.ViewCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT a.Id) AS AnswerCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    MAX(v.CreationDate) AS LastVoteDate,
    ph.CreationDate AS LastEditDate,
    pt.Name AS PostType,
    bt.Name AS BadgeName
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
LEFT JOIN 
    Badges bt ON b.Id = bt.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY 
    p.Id, u.DisplayName, u.Reputation, ph.CreationDate, pt.Name
ORDER BY 
    p.Score DESC, p.ViewCount DESC;

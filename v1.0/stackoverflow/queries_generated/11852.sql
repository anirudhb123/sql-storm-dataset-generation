-- Performance benchmarking query to evaluate various aspects of the StackOverflow schema
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    pt.Name AS PostType,
    ht.Name AS HistoryType,
    MAX(ph.CreationDate) AS LastEditedDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    PostHistoryTypes ht ON ph.PostHistoryTypeId = ht.Id
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.CreationDate >= '2022-01-01'  -- Adjust date range as needed
GROUP BY 
    p.Id, u.DisplayName, pt.Name
ORDER BY 
    p.ViewCount DESC, p.Score DESC
LIMIT 100;  -- Limit the number of results for benchmarking

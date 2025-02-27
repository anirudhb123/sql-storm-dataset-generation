-- Performance Benchmarking SQL Query

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    pt.Name AS PostType,
    COALESCE(AVG(vt.Name = 'UpMod'), 0) AS Upvotes,
    COALESCE(AVG(vt.Name = 'DownMod'), 0) AS Downvotes
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
WHERE 
    p.CreationDate >= '2023-01-01'  -- Adjust the date filter as needed
GROUP BY 
    p.Id, u.DisplayName, pt.Name
ORDER BY 
    p.Score DESC, p.ViewCount DESC
LIMIT 100;  -- Limit the results for benchmarking

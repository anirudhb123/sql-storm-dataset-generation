-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
    COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
    p.AnswerCount,
    (SELECT COUNT(*) FROM PostLinks pl WHERE pl.PostId = p.Id) AS RelatedPostCount,
    (SELECT COUNT(*) FROM PostHistory h WHERE h.PostId = p.Id) AS RevisionCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2023-01-01' -- Filtering posts created in 2023
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC;

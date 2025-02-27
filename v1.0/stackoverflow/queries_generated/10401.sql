-- Performance benchmarking query on Stack Overflow schema

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    pt.Name AS PostType,
    (SELECT COUNT(*) FROM Answers a WHERE a.ParentId = p.Id) AS AnswerCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY 
    p.Id, pt.Name, u.Id
ORDER BY 
    p.CreationDate DESC
LIMIT 100;

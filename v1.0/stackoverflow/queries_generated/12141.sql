-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    (SELECT COUNT(*) 
     FROM Posts AS p2
     WHERE p2.ParentId = p.Id) AS AnswerCount,
    AVG(DATEDIFF(NOW(), p.CreationDate)) AS AvgTimeToVote,
    AVG(DATEDIFF(NOW(), c.CreationDate)) AS AvgTimeToComment
FROM 
    Posts AS p
LEFT JOIN 
    Users AS u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments AS c ON p.Id = c.PostId
LEFT JOIN 
    Votes AS v ON p.Id = v.PostId
WHERE 
    p.PostTypeId = 1 -- Questions only
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Limiting the returned results for performance

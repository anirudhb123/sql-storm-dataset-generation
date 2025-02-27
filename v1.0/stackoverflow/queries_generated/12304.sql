-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerName,
    COUNT(DISTINCT a.Id) AS AnswerCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    p.Score,
    p.ViewCount
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2 -- Answers
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.PostTypeId = 1 -- Questions
GROUP BY 
    p.Id, p.Title, p.CreationDate, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Adjust the LIMIT for performance testing

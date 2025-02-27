-- Performance Benchmarking Query

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.FavoriteCount,
    p.ClosedDate,
    p.LastActivityDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.PostTypeId = 1 -- Only Questions
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Limit to 100 most recent questions

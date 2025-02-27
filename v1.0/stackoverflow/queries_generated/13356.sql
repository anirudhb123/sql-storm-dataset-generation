-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId, 
    p.Title,
    p.CreationDate, 
    p.Score, 
    p.ViewCount, 
    COUNT(DISTINCT c.Id) AS CommentCount, 
    COUNT(DISTINCT a.Id) AS AnswerCount,
    u.DisplayName AS OwnerDisplayName,
    CASE
        WHEN p.PostTypeId = 1 THEN 'Question'
        WHEN p.PostTypeId = 2 THEN 'Answer'
        ELSE 'Other'
    END AS PostType,
    p.Tags
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Posts a ON p.Id = a.ParentId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate > CURRENT_DATE - INTERVAL '30 days'
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 100;


SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    CASE
        WHEN p.PostTypeId = 1 THEN 'Question'
        WHEN p.PostTypeId = 2 THEN 'Answer'
        ELSE 'Other'
    END AS PostType,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    COUNT(DISTINCT b.Id) AS BadgeCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON c.PostId = p.Id
LEFT JOIN 
    Votes v ON v.PostId = p.Id
LEFT JOIN 
    Badges b ON b.UserId = u.Id
WHERE 
    p.CreationDate >= '2023-01-01' AND p.CreationDate < '2024-01-01'
GROUP BY 
    p.Id, p.Title, u.DisplayName, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, p.PostTypeId
ORDER BY 
    p.CreationDate DESC;

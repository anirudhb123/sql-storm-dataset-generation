
SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    p.AnswerCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1
GROUP BY 
    p.Id, p.Title, u.DisplayName, p.CreationDate, p.ViewCount, p.Score, p.AnswerCount
ORDER BY 
    p.CreationDate DESC
LIMIT 10;

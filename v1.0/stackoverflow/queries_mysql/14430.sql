
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    u.Id AS UserId,
    u.Reputation AS UserReputation,
    u.DisplayName AS UserDisplayName,
    c.Id AS CommentId,
    c.Score AS CommentScore,
    c.Text AS CommentText,
    c.CreationDate AS CommentCreationDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.CreationDate >= '2023-01-01' 
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, 
    p.CommentCount, u.Id, u.Reputation, u.DisplayName, 
    c.Id, c.Score, c.Text, c.CreationDate
ORDER BY 
    p.CreationDate DESC
LIMIT 100;

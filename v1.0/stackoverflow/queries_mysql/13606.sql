
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    u.Reputation AS OwnerReputation,
    u.DisplayName AS OwnerDisplayName,
    COUNT(v.Id) AS VoteCount,
    AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
    AVG(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
    p.Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, 
    u.Reputation, u.DisplayName, p.Tags
ORDER BY 
    p.CreationDate DESC
LIMIT 100;

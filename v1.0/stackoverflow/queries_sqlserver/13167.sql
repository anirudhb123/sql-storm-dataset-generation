
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    u.Reputation AS OwnerReputation,
    u.DisplayName AS OwnerDisplayName,
    COALESCE(v.VoteCount, 0) AS VoteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT 
         PostId, 
         COUNT(*) AS VoteCount 
     FROM 
         Votes 
     GROUP BY 
         PostId) v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.CreationDate >= '2022-01-01' 
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.AnswerCount, 
    u.Reputation, u.DisplayName, v.VoteCount
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;

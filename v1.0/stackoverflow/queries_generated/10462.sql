SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    p.FavoriteCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(v.Id) AS TotalVotes,
    bh.CreationDate AS LastEditDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostHistory bh ON p.Id = bh.PostId
WHERE 
    p.PostTypeId IN (1, 2)  -- Select only questions and answers
GROUP BY 
    p.Id, u.DisplayName, bh.CreationDate
ORDER BY 
    p.CreationDate DESC
LIMIT 100;

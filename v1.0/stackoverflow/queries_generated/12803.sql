-- Performance Benchmarking Query

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(c.Id) AS CommentCountTotal,
    COUNT(v.Id) AS VoteCountTotal,
    PH.CreationDate AS LastEditDate,
    PH.UserDisplayName AS LastEditorDisplayName
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostHistory PH ON p.Id = PH.PostId 
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY 
    p.Id, u.Id, PH.CreationDate, PH.UserDisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 100;

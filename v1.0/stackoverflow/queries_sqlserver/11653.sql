
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    t.TagName
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
OUTER APPLY 
    (SELECT value AS TagName FROM STRING_SPLIT(p.Tags, ',')) AS t  
GROUP BY 
    p.Id, u.DisplayName, u.Reputation, p.Title, p.CreationDate, p.Score, p.ViewCount, t.TagName
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;

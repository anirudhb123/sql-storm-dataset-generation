
SELECT 
    p.Id AS PostId,
    p.Title,
    p.ViewCount,
    p.Score,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    STRING_AGG(DISTINCT t.TagName, ',') AS Tags 
FROM 
    Posts p 
JOIN 
    Users u ON p.OwnerUserId = u.Id 
LEFT JOIN 
    Comments c ON p.Id = c.PostId 
LEFT JOIN 
    Votes v ON p.Id = v.PostId 
LEFT JOIN 
    STRING_SPLIT(p.Tags, '>') AS tag ON 1=1 
LEFT JOIN 
    Tags t ON tag.value = t.TagName 
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Id, p.Title, p.ViewCount, p.Score, p.CreationDate, u.DisplayName, u.Reputation 
ORDER BY 
    p.CreationDate DESC 
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;

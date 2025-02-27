
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
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
OUTER APPLY 
    (SELECT value AS TagName FROM STRING_SPLIT(p.Tags, '><')) AS t
WHERE 
    p.CreationDate >= CAST('2024-10-01' AS DATE) - 30  
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, u.Reputation
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;

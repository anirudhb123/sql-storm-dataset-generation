
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    COUNT(v.Id) AS VoteCount,
    COUNT(c.Id) AS CommentCount,
    COUNT(b.Id) AS BadgeCount,
    STRING_AGG(DISTINCT t.TagName, ',') AS Tags,
    u.Reputation,
    u.DisplayName AS OwnerDisplayName,
    u.Location
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    STRING_SPLIT(p.Tags, ',') AS tag_name ON 1 = 1
LEFT JOIN 
    Tags t ON t.TagName = tag_name.value
WHERE 
    p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL '1 year'
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, 
    u.Reputation, u.DisplayName, u.Location
ORDER BY 
    p.Score DESC, p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;

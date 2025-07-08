
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    p.FavoriteCount,
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    u.CreationDate AS UserCreationDate,
    COUNT(c.Id) AS CommentCount,
    LISTAGG(DISTINCT t.TagName, ',') WITHIN GROUP (ORDER BY t.TagName) AS Tags,
    LISTAGG(DISTINCT bh.UserDisplayName, ',') WITHIN GROUP (ORDER BY bh.UserDisplayName) AS Editors
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    PostHistory bh ON p.Id = bh.PostId
LEFT JOIN 
    LATERAL FLATTEN(input => SPLIT(p.Tags, ',')) AS tag ON TRUE
LEFT JOIN 
    Tags t ON t.TagName = TRIM(tag.VALUE)
WHERE 
    p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, 
    p.CommentCount, p.FavoriteCount, u.Id, u.DisplayName, 
    u.Reputation, u.CreationDate
ORDER BY 
    p.CreationDate DESC
LIMIT 
    100;

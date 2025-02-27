
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
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    STRING_AGG(DISTINCT bh.UserDisplayName, ', ') AS Editors
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    PostHistory bh ON p.Id = bh.PostId
CROSS APPLY 
    STRING_SPLIT(p.Tags, ',') AS tag
LEFT JOIN 
    Tags t ON t.TagName = LTRIM(tag.value)
WHERE 
    p.CreationDate >= SYSDATETIME() - INTERVAL '1 year' 
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, 
    p.CommentCount, p.FavoriteCount, u.Id, u.DisplayName, 
    u.Reputation, u.CreationDate
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS 
FETCH NEXT 100 ROWS ONLY;

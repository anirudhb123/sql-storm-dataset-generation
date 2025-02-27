
SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    p.CreationDate,
    p.LastEditDate,
    p.Score,
    p.ViewCount,
    t.TagName
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    (SELECT DISTINCT value AS TagName FROM STRING_SPLIT(p.Tags, ',')) AS t ON 1 = 1
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Id, p.Title, u.DisplayName, p.CreationDate, p.LastEditDate, p.Score, p.ViewCount, t.TagName
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;

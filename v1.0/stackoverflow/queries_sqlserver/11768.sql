
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    STRING_AGG(DISTINCT t.TagName, ',') AS Tags,
    COUNT(DISTINCT b.Id) AS BadgeCount
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
CROSS APPLY 
    STRING_SPLIT(p.Tags, ',') AS tagsl
LEFT JOIN 
    Tags t ON t.TagName = LTRIM(RTRIM(tagsl.value))
WHERE 
    p.CreationDate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score
ORDER BY 
    p.Score DESC
OFFSET 0 ROWS 
FETCH NEXT 100 ROWS ONLY;

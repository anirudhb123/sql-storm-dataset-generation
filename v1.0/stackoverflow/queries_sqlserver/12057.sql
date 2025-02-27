
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    u.DisplayName AS OwnerDisplayName,
    COUNT(co.Id) AS CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id) AS VoteCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments co ON p.Id = co.PostId
OUTER APPLY (SELECT value AS tag FROM STRING_SPLIT(p.Tags, '><')) AS tag
LEFT JOIN 
    Tags t ON t.TagName = tag.tag
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, u.DisplayName
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;

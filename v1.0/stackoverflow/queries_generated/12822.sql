SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    (SELECT COUNT(*) FROM Posts WHERE ParentId = p.Id) AS AnswerCount,
    STRING_AGG(t.TagName, ', ') AS Tags
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    STRING_SPLIT(p.Tags, ', ') AS t ON t.TagName IS NOT NULL
WHERE 
    p.CreationDate >= DATEADD(year, -1, GETDATE())
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
ORDER BY 
    p.ViewCount DESC;

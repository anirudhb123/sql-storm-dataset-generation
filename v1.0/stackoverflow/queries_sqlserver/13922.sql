
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.AnswerCount,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
    STRING_AGG(t.TagName, ', ') AS Tags
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    STRING_SPLIT(p.Tags, ',') AS tag ON 1 = 1
LEFT JOIN 
    Tags t ON tag.value = t.TagName
WHERE 
    p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, p.AnswerCount, p.Score, u.DisplayName
ORDER BY 
    p.Score DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;

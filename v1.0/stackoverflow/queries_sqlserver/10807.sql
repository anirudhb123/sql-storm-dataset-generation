
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    u.DisplayName AS OwnerDisplayName,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    STRING_SPLIT(p.Tags, ',') AS tag_array ON 1=1
LEFT JOIN 
    Tags t ON t.TagName = tag_array.value
WHERE 
    p.CreationDate >= '2023-01-01'
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, u.DisplayName
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;

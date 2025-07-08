
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
    LISTAGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    LATERAL FLATTEN(INPUT => SPLIT(p.Tags, ',')) AS tag_array ON TRUE
LEFT JOIN 
    Tags t ON t.TagName = tag_array.VALUE
WHERE 
    p.CreationDate >= '2023-01-01'
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 100;

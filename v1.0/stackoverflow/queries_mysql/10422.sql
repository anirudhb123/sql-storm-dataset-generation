
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    p.CommentCount,
    p.FavoriteCount,
    t.TagName,
    v.VoteTypeId,
    COUNT(v.Id) AS VoteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Tags t ON t.ExcerptPostId = p.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= CURDATE() - INTERVAL 6 MONTH
GROUP BY 
    p.Id, p.Title, p.CreationDate, u.DisplayName, p.ViewCount, p.Score, 
    p.AnswerCount, p.CommentCount, p.FavoriteCount, t.TagName, v.VoteTypeId
ORDER BY 
    p.CreationDate DESC;

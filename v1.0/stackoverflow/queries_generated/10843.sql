-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    p.FavoriteCount,
    u.DisplayName AS OwnerDisplayName,
    t.TagName,
    v.VoteTypeId,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Tags t ON t.WikiPostId = p.Id OR t.ExcerptPostId = p.Id
LEFT JOIN 
    Votes v ON v.PostId = p.Id
LEFT JOIN 
    Comments c ON c.PostId = p.Id
WHERE 
    p.CreationDate >= DATEADD(year, -1, GETDATE()) -- posts created within the last year
GROUP BY 
    p.Id, u.DisplayName, t.TagName, v.VoteTypeId
ORDER BY 
    p.CreationDate DESC;

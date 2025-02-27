
SELECT 
    p.Id AS PostId, 
    p.Title, 
    p.CreationDate, 
    p.ViewCount, 
    p.Score, 
    u.DisplayName AS OwnerDisplayName, 
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes, 
    COUNT(DISTINCT c.Id) AS CommentCount, 
    COUNT(DISTINCT b.Id) AS BadgeCount, 
    STRING_AGG(DISTINCT t.TagName, ',') AS Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    Tags t ON t.ExcerptPostId = p.Id OR t.WikiPostId = p.Id
WHERE 
    p.PostTypeId IN (1, 2) AND 
    p.CreationDate >= CAST(DATEADD(YEAR, -1, '2024-10-01') AS DATE)
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
ORDER BY 
    p.Score DESC, p.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;

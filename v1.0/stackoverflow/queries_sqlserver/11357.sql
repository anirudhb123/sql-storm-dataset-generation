
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    p.AnswerCount,
    COALESCE(c.CommentCount, 0) AS CommentCount,
    COALESCE(pl.LinksCount, 0) AS LinksCount,
    COALESCE(ph.HistoryCount, 0) AS HistoryCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS LinksCount FROM PostLinks GROUP BY PostId) pl ON p.Id = pl.PostId
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS HistoryCount FROM PostHistory GROUP BY PostId) ph ON p.Id = ph.PostId
WHERE 
    p.CreationDate >= CAST(DATEADD(YEAR, -1, '2024-10-01') AS DATE) 
GROUP BY 
    p.Id,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName,
    u.Reputation,
    p.AnswerCount,
    c.CommentCount,
    pl.LinksCount,
    ph.HistoryCount
ORDER BY 
    p.Score DESC, 
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;

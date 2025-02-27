
SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    p.CreationDate,
    p.LastEditDate,
    p.Score,
    p.ViewCount,
    t.TagName
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', n.n), ',', -1) AS TagName
     FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
           UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
           UNION ALL SELECT 9 UNION ALL SELECT 10) n
     WHERE n.n <= 1 + LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, ',', ''))) AS t ON TRUE
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Id, p.Title, u.DisplayName, p.CreationDate, p.LastEditDate, p.Score, p.ViewCount, t.TagName
ORDER BY 
    p.CreationDate DESC
LIMIT 100;

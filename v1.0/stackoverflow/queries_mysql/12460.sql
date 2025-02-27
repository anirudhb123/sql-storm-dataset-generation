
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    u.DisplayName AS OwnerDisplayName,
    t.TagName
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    (SELECT TRIM(tag) AS TagName FROM (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', n.n), ',', -1) AS tag
    FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
          UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n
    WHERE n.n <= LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, ',', '')) + 1) AS tag) AS tags ON TRUE
LEFT JOIN 
    Tags t ON t.TagName = tags.TagName
WHERE 
    p.CreationDate >= '2023-01-01'
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, t.TagName
ORDER BY 
    p.CreationDate DESC
LIMIT 100;

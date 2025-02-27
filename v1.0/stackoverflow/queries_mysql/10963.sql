
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    p.Score,
    p.ViewCount,
    GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName ASC SEPARATOR ', ') AS Tags
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS tag
     FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
           UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 
           UNION ALL SELECT 10) numbers
     WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1) AS tag ON TRUE
LEFT JOIN 
    Tags t ON tag = t.TagName
GROUP BY 
    p.Id, p.Title, p.CreationDate, u.DisplayName, p.Score, p.ViewCount
ORDER BY 
    p.CreationDate DESC
LIMIT 100;

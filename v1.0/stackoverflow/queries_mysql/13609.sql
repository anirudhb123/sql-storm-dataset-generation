
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    COUNT(v.Id) AS VoteCount,
    COUNT(c.Id) AS CommentCount,
    COUNT(b.Id) AS BadgeCount,
    GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
    u.Reputation,
    u.DisplayName AS OwnerDisplayName,
    u.Location
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS tag_name
    FROM 
    (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL
     SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
    WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1) AS tag_name ON true
LEFT JOIN 
    Tags t ON t.TagName = tag_name
WHERE 
    p.CreationDate >= NOW() - INTERVAL 1 YEAR
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, 
    u.Reputation, u.DisplayName, u.Location
ORDER BY 
    p.Score DESC, p.CreationDate DESC
LIMIT 100;

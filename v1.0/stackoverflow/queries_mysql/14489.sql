
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.LastActivityDate,
    p.Score,
    p.ViewCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    GROUP_CONCAT(DISTINCT t.TagName) AS Tags
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    (SELECT TRIM(BOTH ' ' FROM tag) AS tag FROM (SELECT TRIM(BOTH ' ' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS tag FROM (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1) tags) AS tag_table ON TRUE
LEFT JOIN 
    Tags t ON t.TagName = tag_table.tag
WHERE 
    p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.LastActivityDate, p.Score, p.ViewCount
ORDER BY 
    p.LastActivityDate DESC
LIMIT 100;


SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    u.DisplayName AS OwnerDisplayName,
    COUNT(co.Id) AS CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id) AS VoteCount,
    GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments co ON p.Id = co.PostId
LEFT JOIN 
    (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) tag
     FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL
           SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL
           SELECT 9 UNION ALL SELECT 10) numbers 
     WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tag ON true
LEFT JOIN 
    Tags t ON t.TagName = tag.tag
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 100;

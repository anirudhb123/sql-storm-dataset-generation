
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    (SELECT COUNT(*) 
     FROM Posts AS a 
     WHERE a.ParentId = p.Id) AS AnswerCount,
    GROUP_CONCAT(DISTINCT t.TagName) AS Tags
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN Comments c ON p.Id = c.PostId
LEFT JOIN Votes v ON p.Id = v.PostId
LEFT JOIN (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS TagName
    FROM 
        (SELECT @row := @row + 1 AS n
         FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION 
               SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION 
               SELECT 9 UNION SELECT 10) n,
         (SELECT @row := 0) r) n
    WHERE n.n <= 1 + (LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', '')))/LENGTH('><')
) t ON true
WHERE p.PostTypeId = 1 
GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
ORDER BY p.CreationDate DESC
LIMIT 100;

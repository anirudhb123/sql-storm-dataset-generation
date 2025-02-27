
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    p.CommentCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(v.Id) AS VoteCount,
    COUNT(c.Id) AS CommentCount,
    pt.Name AS PostType,
    GROUP_CONCAT(t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    (SELECT DISTINCT TRIM(tag) AS tag FROM (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS tag
      FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
            UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
      WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1) AS tag_table) AS t 
ON tag = t.tag
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.AnswerCount, p.CommentCount, 
    u.DisplayName, u.Reputation, pt.Name
ORDER BY 
    p.CreationDate DESC
LIMIT 100;

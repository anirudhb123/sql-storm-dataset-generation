
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
    (SELECT COUNT(1) FROM Posts WHERE ParentId = p.Id) AS AnswerCount,
    pt.Name AS PostTypeName,
    GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', n.n), ',', -1)) AS TagName
     FROM Posts p
     JOIN (SELECT a.N + b.N * 10 + 1 n
           FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
                (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b) n
     WHERE n.n <= 1 + LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, ',', ''))) AS t ON TRUE
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName, pt.Name
ORDER BY 
    p.Score DESC
LIMIT 100;

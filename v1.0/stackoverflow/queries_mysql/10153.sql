
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
    GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
    u.DisplayName AS OwnerDisplayName,
    
    UNIX_TIMESTAMP('2024-10-01 12:34:56') AS BenchmarkStartTime
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1) AS TagName 
     FROM 
     (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION 
      SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers 
     WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1) AS tag ON TRUE
LEFT JOIN 
    Tags t ON t.TagName = tag.TagName
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 100;

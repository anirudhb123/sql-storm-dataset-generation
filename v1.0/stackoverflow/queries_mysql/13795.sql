
SELECT 
    p.Id AS PostId,
    p.Title AS PostTitle,
    p.PostTypeId,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    u.DisplayName AS OwnerDisplayName,
    t.TagName AS TagName
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT p2.Id, SUBSTRING_INDEX(SUBSTRING_INDEX(p2.Tags, ',', numbers.n), ',', -1) AS TagName 
     FROM Posts p2 
     JOIN (SELECT @row := @row + 1 AS n 
           FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) 
           numbers, (SELECT @row := 0) r) numbers 
     ON CHAR_LENGTH(p2.Tags) - CHAR_LENGTH(REPLACE(p2.Tags, ',', '')) >= numbers.n - 1) t 
     ON p.Id = t.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL 1 YEAR
GROUP BY 
    p.Id, p.Title, p.PostTypeId, p.CreationDate, p.ViewCount, p.Score, 
    u.DisplayName, t.TagName
ORDER BY 
    p.ViewCount DESC
LIMIT 100;


SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS Author,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes, 
    p.CreationDate,
    p.LastActivityDate,
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
    (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1) AS tag
     FROM 
     (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
      SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
      SELECT 9 UNION ALL SELECT 10) numbers
     WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1) AS tag 
ON TRUE
LEFT JOIN 
    Tags t ON tag.tag = t.TagName
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Id, p.Title, u.DisplayName, p.CreationDate, p.LastActivityDate, t.TagName
ORDER BY 
    p.CreationDate DESC;

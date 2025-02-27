
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.Reputation AS OwnerReputation,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    (SELECT DISTINCT p.Id, SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '<>', n.n), '<>', -1) AS tag_id 
     FROM Posts p 
     JOIN (SELECT @row := @row + 1 AS n FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) t, (SELECT @row := 0) r) n 
     WHERE n.n <= LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '<>', '')) + 1) AS tag_id ON p.Id = tag_id.Id
LEFT JOIN 
    Tags t ON tag_id.tag_id = t.TagName
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.Reputation
ORDER BY 
    p.CreationDate DESC;

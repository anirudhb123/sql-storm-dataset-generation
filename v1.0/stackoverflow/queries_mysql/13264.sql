
SELECT 
    p.Id AS PostId,
    p.Title,
    p.ViewCount,
    p.Score,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
    p.AcceptedAnswerId,
    MAX(ph.CreationDate) AS LastEdited
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    (SELECT DISTINCT tag_ids FROM (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', n.n), '>', -1) AS tag_ids 
        FROM Posts p CROSS JOIN (SELECT a.N + b.N * 10 AS n 
        FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a 
        CROSS JOIN (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b) n 
        WHERE n.n < LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '>', '')) + 1) AS tag_ids) AS tag_ids ON true
LEFT JOIN 
    Tags t ON t.TagName = tag_ids.tag_ids
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
GROUP BY 
    p.Id, p.Title, p.ViewCount, p.Score, p.CreationDate, u.DisplayName, p.AcceptedAnswerId
ORDER BY 
    p.Score DESC, p.ViewCount DESC
LIMIT 100;

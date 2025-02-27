
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(v.BountyAmount) AS TotalBounty,
    GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    ph.CreationDate AS LastHistoryUpdate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS tag_name
     FROM 
         (SELECT @row := @row + 1 AS n FROM 
             (SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) t1,
             (SELECT @row := 0) t2) n
     WHERE 
         n.n <= LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', '')) + 1) a ON TRUE
LEFT JOIN 
    Tags t ON a.tag_name = t.TagName
WHERE 
    p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 MONTH 
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, u.DisplayName, u.Reputation, ph.CreationDate
ORDER BY 
    p.CreationDate DESC;

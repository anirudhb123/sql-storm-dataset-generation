
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS TotalDownVotes,
    GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName ASC SEPARATOR ', ') AS Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
LEFT JOIN 
    (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1)) AS tag
     FROM 
         (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers 
     WHERE 
         CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1) AS tag ON tag IS NOT NULL
LEFT JOIN 
    Tags t ON t.TagName = tag
WHERE 
    p.CreationDate >= NOW() - INTERVAL 1 YEAR  
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, u.Reputation
ORDER BY 
    p.ViewCount DESC
LIMIT 100;

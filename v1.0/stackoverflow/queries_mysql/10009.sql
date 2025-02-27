
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(v.Id) AS VoteCount,
    GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '<>', numbers.n), '<>', -1) AS tag
     FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
           SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
           SELECT 9 UNION ALL SELECT 10) numbers 
     WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '<>', '')) >= numbers.n - 1) AS tag ON tag IS NOT NULL
LEFT JOIN 
    Tags t ON t.TagName = tag
WHERE 
    p.CreationDate > '2020-01-01' 
GROUP BY 
    p.Id, p.Title, p.CreationDate, u.DisplayName, u.Reputation
ORDER BY 
    p.CreationDate DESC;


SELECT 
    p.Id AS PostId, 
    p.Title, 
    p.ViewCount, 
    u.DisplayName AS OwnerDisplayName, 
    GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '> <', numbers.n), '> <', -1)) AS tag_name
     FROM 
     (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
      UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
     WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '> <', '')) >= numbers.n - 1) AS tag_name ON TRUE
JOIN 
    Tags t ON tag_name.tag_name = t.TagName
WHERE 
    p.PostTypeId = 1  
GROUP BY 
    p.Id, p.Title, p.ViewCount, u.DisplayName
ORDER BY 
    p.ViewCount DESC
LIMIT 10;

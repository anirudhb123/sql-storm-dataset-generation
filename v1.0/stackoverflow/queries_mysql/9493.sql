
SELECT 
    u.DisplayName AS UserDisplayName,
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COALESCE(SUM(CASE WHEN bh.UserId IS NOT NULL THEN 1 ELSE 0 END), 0) AS TotalBadges,
    AVG(u.Reputation) AS AverageUserReputation,
    GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS AssociatedTags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Badges bh ON u.Id = bh.UserId
LEFT JOIN 
    (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS tag_name
     FROM 
         (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
          UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
     WHERE 
         CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1) AS tag_name ON tag_name IS NOT NULL
JOIN 
    Tags t ON t.TagName = TRIM(tag_name)
WHERE 
    p.CreationDate >= TIMESTAMP('2024-10-01 12:34:56') - INTERVAL 1 YEAR
    AND p.PostTypeId = 1
GROUP BY 
    u.DisplayName, p.Title, p.CreationDate, u.Reputation
ORDER BY 
    TotalVotes DESC, AverageUserReputation DESC;

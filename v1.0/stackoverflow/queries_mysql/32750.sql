
WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        Id, 
        Reputation, 
        CreationDate, 
        DisplayName,
        LastAccessDate,
        0 AS Level
    FROM 
        Users
    WHERE 
        Reputation > 1000  
    
    UNION ALL
    
    SELECT 
        u.Id, 
        u.Reputation, 
        u.CreationDate, 
        u.DisplayName,
        u.LastAccessDate,
        ur.Level + 1
    FROM 
        Users u
    JOIN 
        UserReputationCTE ur ON ur.Reputation < u.Reputation
    WHERE 
        u.Reputation < 10000  
)
SELECT 
    u.DisplayName, 
    u.Reputation,
    COUNT(p.Id) AS PostCount,
    SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
    SUM(CASE WHEN ph.Id IS NOT NULL THEN 1 ELSE 0 END) AS PostsWithHistory,
    GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName ASC SEPARATOR ', ') AS AssociatedTags
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    (SELECT 
        p.Id,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1) AS TagName
    FROM 
        Posts p 
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1) t ON true
WHERE 
    u.LastAccessDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR  
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC, 
    PostCount DESC
LIMIT 10;

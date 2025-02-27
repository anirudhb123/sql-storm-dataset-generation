
WITH ProcessedTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts p
    JOIN 
        (SELECT a.N + b.N * 10 + 1 n
         FROM 
           (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
            UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
           (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
            UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
         ORDER BY n) numbers 
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1  
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    pt.Tag,
    COUNT(DISTINCT pt.PostId) AS QuestionCount,
    AVG(ur.Reputation) AS AverageReputation,
    SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
    SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
    SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
FROM 
    ProcessedTags pt
JOIN 
    Posts p ON pt.PostId = p.Id
JOIN 
    UserReputation ur ON p.OwnerUserId = ur.UserId
LEFT JOIN 
    Badges b ON ur.UserId = b.UserId
WHERE 
    p.CreationDate >= '2023-01-01' AND
    p.CreationDate < '2024-01-01'  
GROUP BY 
    pt.Tag, p.Title, ur.UserId, ur.DisplayName, ur.Reputation
ORDER BY 
    QuestionCount DESC, AverageReputation DESC;

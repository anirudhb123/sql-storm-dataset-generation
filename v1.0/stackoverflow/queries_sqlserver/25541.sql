
WITH ProcessedTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        value AS Tag
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') 
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
    pt.Tag, ur.Reputation
ORDER BY 
    QuestionCount DESC, AverageReputation DESC;

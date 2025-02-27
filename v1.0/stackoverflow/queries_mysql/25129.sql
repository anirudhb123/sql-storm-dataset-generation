
WITH TagPostCounts AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<%s>', t.TagName, '<%s>%')  
    GROUP BY 
        t.TagName
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id AND p.PostTypeId = 1  
    GROUP BY 
        u.Id, u.Reputation
),
BadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
FinalResult AS (
    SELECT 
        up.UserId,
        up.Reputation,
        up.QuestionCount,
        up.AnswerCount,
        COALESCE(bc.BadgeCount, 0) AS BadgeCount,
        COALESCE(tpc.PostCount, 0) AS TotalTags
    FROM 
        UserReputation up
    LEFT JOIN 
        BadgeCounts bc ON up.UserId = bc.UserId
    LEFT JOIN 
        TagPostCounts tpc ON tpc.PostCount > 0
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    fr.Reputation,
    fr.QuestionCount,
    fr.AnswerCount,
    fr.BadgeCount,
    fr.TotalTags,
    GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
FROM 
    Users u
JOIN 
    FinalResult fr ON u.Id = fr.UserId
LEFT JOIN 
    Posts p ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1) AS TagName
     FROM 
        (SELECT @row := @row + 1 AS n
         FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
               UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers,
         (SELECT @row := 0) r) numbers
     WHERE numbers.n <= CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) + 1) AS t ON t.TagName IS NOT NULL
WHERE 
    u.Reputation >= 1000  
GROUP BY 
    u.Id, u.DisplayName, fr.Reputation, fr.QuestionCount, fr.AnswerCount, fr.BadgeCount, fr.TotalTags
ORDER BY 
    fr.Reputation DESC, fr.QuestionCount DESC, fr.AnswerCount DESC;

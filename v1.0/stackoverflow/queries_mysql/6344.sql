
SELECT 
    u.DisplayName AS UserName,
    COUNT(p.Id) AS PostCount,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
    AVG(u.Reputation) AS AvgReputation,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS AssociatedTags
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    (SELECT DISTINCT TRIM(tag) AS tag FROM Posts p CROSS JOIN (SELECT @p := SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1) AS tag
FROM 
    (SELECT @counter := @counter + 1 AS n FROM 
        (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
         UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 
         UNION SELECT 10) numbers, (SELECT @counter := 0) init
    ) AS numbers 
    WHERE @p IS NOT NULL) AS tags ON TRUE
LEFT JOIN 
    Tags t ON tag = t.TagName
WHERE 
    u.LastAccessDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
GROUP BY 
    u.DisplayName, u.Reputation
HAVING 
    COUNT(p.Id) > 0
ORDER BY 
    PostCount DESC, AvgReputation DESC
LIMIT 100;

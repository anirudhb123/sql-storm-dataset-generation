
WITH TagStats AS (
    SELECT
        LTRIM(RTRIM(value)) AS TagName,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') 
    GROUP BY 
        LTRIM(RTRIM(value))
), 

UserBadgeStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),

ActiveUsers AS (
    SELECT
        Id,
        DisplayName,
        Reputation,
        LastAccessDate,
        CreationDate
    FROM 
        Users
    WHERE 
        LastAccessDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
)

SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ubs.DisplayName AS UserWithMostGoldBadges,
    ubs.GoldBadges,
    ubs.SilverBadges,
    ubs.BronzeBadges,
    au.DisplayName AS ActiveUser,
    au.Reputation,
    au.CreationDate
FROM 
    TagStats ts
JOIN 
    UserBadgeStats ubs ON ubs.GoldBadges = (SELECT MAX(GoldBadges) FROM UserBadgeStats)
JOIN 
    ActiveUsers au ON au.Reputation = (SELECT MAX(Reputation) FROM ActiveUsers)
ORDER BY 
    ts.PostCount DESC, 
    ubs.GoldBadges DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

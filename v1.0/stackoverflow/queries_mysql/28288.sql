
WITH TagStats AS (
    SELECT
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1)) AS TagName,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM
        Posts
    JOIN (
        SELECT 
            a.N + 1 AS n
        FROM 
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 
             UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 
             UNION ALL SELECT 8 UNION ALL SELECT 9) a,
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 
             UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 
             UNION ALL SELECT 8 UNION ALL SELECT 9) b
    ) n ON CHAR_LENGTH(Tags)
    -CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    GROUP BY
        TagName
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
        LastAccessDate >= (NOW() - INTERVAL 1 YEAR)
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
LIMIT 10;

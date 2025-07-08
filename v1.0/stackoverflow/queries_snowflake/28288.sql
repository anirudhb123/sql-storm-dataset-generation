
WITH TagStats AS (
    SELECT
        TRIM(SPLIT_PART(Tags, '><', seq)) AS TagName,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM (
        SELECT 
            Tags, 
            PostTypeId,
            ROW_NUMBER() OVER (PARTITION BY Tags ORDER BY NULL) AS seq
        FROM
            Posts
        JOIN 
            (SELECT ROW_NUMBER() OVER () as seq FROM TABLE(GENERATOR(ROWS => 1000))) seqs ON seqs.seq <= LENGTH(Tags) - LENGTH(REPLACE(Tags, '><', '')) + 1
    )
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
        LastAccessDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
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


WITH UserBadgeCounts AS (
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
RecentPostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, -1, GETDATE())
    GROUP BY 
        p.OwnerUserId
),
TopUsers AS (
    SELECT 
        ubc.UserId,
        ubc.DisplayName,
        ubc.BadgeCount,
        rp.PostCount,
        rp.QuestionCount,
        rp.AnswerCount,
        rp.LastPostDate
    FROM 
        UserBadgeCounts ubc
    JOIN 
        RecentPostStats rp ON ubc.UserId = rp.OwnerUserId
    WHERE 
        ubc.BadgeCount > 0
    ORDER BY 
        ubc.BadgeCount DESC, 
        rp.PostCount DESC
)
SELECT TOP 10
    tu.DisplayName,
    tu.BadgeCount,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    DATEDIFF(SECOND, tu.LastPostDate, CAST('2024-10-01 12:34:56' AS DATETIME)) / 3600.0 AS HoursSinceLastPost
FROM 
    TopUsers tu
ORDER BY 
    tu.BadgeCount DESC, 
    tu.PostCount DESC;

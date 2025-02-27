
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        BadgeCount,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        @row_number := @row_number + 1 AS UserRank
    FROM UserBadges, (SELECT @row_number := 0) AS r
    ORDER BY BadgeCount DESC
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY p.OwnerUserId
)
SELECT 
    tu.DisplayName,
    tu.BadgeCount,
    tu.GoldBadges,
    tu.SilverBadges,
    tu.BronzeBadges,
    ps.PostCount,
    ps.QuestionCount,
    ps.AnswerCount,
    ps.TotalViews
FROM TopUsers tu
JOIN PostStats ps ON tu.UserId = ps.OwnerUserId
WHERE tu.UserRank <= 10
ORDER BY tu.UserRank;

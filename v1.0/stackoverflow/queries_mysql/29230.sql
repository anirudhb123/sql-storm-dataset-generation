
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
TopPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        @PostRank := @PostRank + 1 AS PostRank
    FROM
        Posts p, (SELECT @PostRank := 0) r
    WHERE
        p.PostTypeId = 1  
    ORDER BY
        p.Score DESC
),
UserPostMetrics AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AverageViewCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1  
    GROUP BY
        u.Id, u.DisplayName
),
RankedUsers AS (
    SELECT
        ub.UserId,
        ub.DisplayName,
        ub.BadgeCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        up.QuestionCount,
        up.TotalScore,
        up.AverageViewCount,
        up.AcceptedAnswerCount,
        @UserRank := @UserRank + 1 AS UserRank
    FROM
        UserBadgeCounts ub
    JOIN
        UserPostMetrics up ON ub.UserId = up.UserId,
        (SELECT @UserRank := 0) r
    ORDER BY
        ub.BadgeCount DESC, up.TotalScore DESC
)
SELECT
    ru.UserRank,
    ru.DisplayName,
    ru.BadgeCount,
    ru.GoldBadges,
    ru.SilverBadges,
    ru.BronzeBadges,
    ru.QuestionCount,
    ru.TotalScore,
    ru.AverageViewCount,
    ru.AcceptedAnswerCount,
    tp.Title AS TopPostTitle,
    tp.CreationDate AS TopPostDate
FROM
    RankedUsers ru
LEFT JOIN
    TopPosts tp ON ru.UserId = tp.OwnerUserId
WHERE
    ru.UserRank <= 10  
ORDER BY
    ru.UserRank;

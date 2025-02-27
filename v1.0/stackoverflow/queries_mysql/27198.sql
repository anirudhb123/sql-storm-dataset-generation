
WITH UserBadges AS (
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
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ub.BadgeCount,
        ub.GoldBadges, 
        ub.SilverBadges, 
        ub.BronzeBadges,
        @rownum := @rownum + 1 AS UserRank
    FROM 
        Users u
    JOIN 
        UserBadges ub ON u.Id = ub.UserId,
        (SELECT @rownum := 0) r
    WHERE 
        u.Reputation > 0
    ORDER BY 
        u.Reputation DESC
),
TagPostStats AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p 
    INNER JOIN 
        (SELECT a.N + b.N * 10 + 1 n
         FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a
         CROSS JOIN (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
        ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        Tag
),
PopularTags AS (
    SELECT 
        Tag,
        PostCount,
        TotalViews,
        AvgScore,
        @tagrank := @tagrank + 1 AS TagRank
    FROM 
        TagPostStats,
        (SELECT @tagrank := 0) r
    ORDER BY 
        PostCount DESC
)
SELECT 
    tu.DisplayName, 
    tu.Reputation, 
    tu.BadgeCount,
    tu.GoldBadges,
    tu.SilverBadges,
    tu.BronzeBadges,
    pt.Tag,
    pt.PostCount,
    pt.TotalViews,
    pt.AvgScore
FROM 
    TopUsers tu
JOIN 
    PopularTags pt ON pt.TagRank = 1 
WHERE 
    tu.UserRank <= 10 
ORDER BY 
    tu.Reputation DESC;

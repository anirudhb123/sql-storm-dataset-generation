
WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS TagCount
    FROM Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
    WHERE PostTypeId = 1
    GROUP BY value
    ORDER BY TagCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM Posts p
    WHERE p.PostTypeId IN (1, 2) 
)
SELECT 
    upc.DisplayName,
    upc.PostCount,
    upc.QuestionCount,
    upc.AnswerCount,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    tt.TagName,
    rp.Title AS TopPostTitle,
    rp.CreationDate AS TopPostDate,
    rp.ViewCount AS TopPostViews,
    rp.Score AS TopPostScore
FROM UserPostCounts upc
LEFT JOIN UserBadges ub ON upc.UserId = ub.UserId
CROSS JOIN TopTags tt
LEFT JOIN RankedPosts rp ON upc.UserId = rp.OwnerUserId AND rp.RankByViews = 1
WHERE upc.PostCount > 0
ORDER BY upc.PostCount DESC, upc.UserId DESC, ub.BadgeCount DESC;

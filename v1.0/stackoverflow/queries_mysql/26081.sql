
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
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS TagCount
    FROM Posts
    JOIN (
        SELECT 
            1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
            SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
            SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE PostTypeId = 1
    GROUP BY TagName
    ORDER BY TagCount DESC
    LIMIT 10
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
        @row_number_views := IF(@prev_user_views = p.OwnerUserId, @row_number_views + 1, 1) AS RankByViews,
        @prev_user_views := p.OwnerUserId,
        @row_number_score := IF(@prev_user_score = p.OwnerUserId, @row_number_score + 1, 1) AS RankByScore,
        @prev_user_score := p.OwnerUserId
    FROM Posts p
    JOIN (SELECT @row_number_views := 0, @prev_user_views := NULL, @row_number_score := 0, @prev_user_score := NULL) r
    WHERE p.PostTypeId IN (1, 2) 
    ORDER BY p.OwnerUserId, p.ViewCount DESC, p.Score DESC
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
LEFT JOIN TopTags tt ON TRUE
LEFT JOIN RankedPosts rp ON upc.UserId = rp.OwnerUserId AND rp.RankByViews = 1
WHERE upc.PostCount > 0
ORDER BY upc.PostCount DESC, upc.UserId DESC, ub.BadgeCount DESC;

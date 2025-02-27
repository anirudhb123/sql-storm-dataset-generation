
WITH TagCount AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
        SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
        SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL 
        SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        @rank := IF(@prev = PostCount, @rank, @rowNumber) AS TagRank,
        @prev := PostCount,
        @rowNumber := @rowNumber + 1
    FROM 
        TagCount, (SELECT @rowNumber := 0, @prev := NULL, @rank := 0) r
    WHERE 
        PostCount > 5 
    ORDER BY 
        PostCount DESC
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    tt.Tag,
    tt.PostCount,
    ub.UserId,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId IN (SELECT p.Id FROM Posts p WHERE p.Tags LIKE CONCAT('%', tt.Tag, '%'))) AS TotalVotesForTag
FROM 
    TopTags tt
JOIN 
    Posts p ON p.Tags LIKE CONCAT('%', tt.Tag, '%')
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    UserBadges ub ON u.Id = ub.UserId
ORDER BY 
    tt.PostCount DESC, ub.BadgeCount DESC
LIMIT 10;

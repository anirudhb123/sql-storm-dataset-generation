
WITH ProcessedTags AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
    FROM 
        Posts p
    INNER JOIN (
        SELECT 
            a.N + b.N * 10 + 1 AS n
        FROM 
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
    ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.Tags IS NOT NULL
), TagPostCounts AS (
    SELECT 
        TagName,
        COUNT(DISTINCT PostId) AS PostCount
    FROM 
        ProcessedTags
    GROUP BY 
        TagName
), TopTags AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagPostCounts
    WHERE 
        PostCount > 1
), ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.CreationDate > NOW() - INTERVAL 30 DAY THEN 1 ELSE 0 END) AS ActivePostsLast30Days
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
), UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldCount,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverCount,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.UserId,
    u.DisplayName,
    COALESCE(b.GoldCount, 0) AS GoldBadges,
    COALESCE(b.SilverCount, 0) AS SilverBadges,
    COALESCE(b.BronzeCount, 0) AS BronzeBadges,
    u.PostCount,
    u.ActivePostsLast30Days,
    tt.TagName,
    tt.PostCount AS TagPostCount
FROM 
    ActiveUsers u
LEFT JOIN 
    UserBadges b ON u.UserId = b.UserId
LEFT JOIN 
    TopTags tt ON tt.TagRank <= 5
ORDER BY 
    u.PostCount DESC, u.ActivePostsLast30Days DESC;

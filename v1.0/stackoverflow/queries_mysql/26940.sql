
WITH TagCounts AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1)) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    INNER JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
        SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
        SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL 
        SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16 UNION ALL 
        SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1   
    GROUP BY 
        TagName
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName AS UserName,
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
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        COALESCE(p.CommentCount, 0) AS CommentCount,
        COALESCE(p.ViewCount, 0) AS ViewCount,
        COALESCE(p.FavoriteCount, 0) AS FavoriteCount,
        COALESCE(pb.GoldBadges, 0) AS GoldBadges,
        COALESCE(pb.SilverBadges, 0) AS SilverBadges,
        COALESCE(pb.BronzeBadges, 0) AS BronzeBadges
    FROM 
        Posts p
    LEFT JOIN 
        UserBadges pb ON p.OwnerUserId = pb.UserId
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 30 DAY)
),
TopTags AS (
    SELECT 
        tc.TagName,
        tc.PostCount,
        @rownum := @rownum + 1 AS TagRank
    FROM 
        TagCounts tc, (SELECT @rownum := 0) r
    ORDER BY 
        tc.PostCount DESC
)
SELECT 
    ta.TagName,
    ta.PostCount,
    pa.Title,
    pa.CreationDate,
    pa.AnswerCount,
    pa.CommentCount,
    pa.ViewCount,
    pa.FavoriteCount,
    pa.GoldBadges,
    pa.SilverBadges,
    pa.BronzeBadges
FROM 
    TopTags ta
JOIN 
    PostActivity pa ON pa.PostId IN (
        SELECT 
            p.Id 
        FROM 
            Posts p
        WHERE 
            p.Tags LIKE CONCAT('%', ta.TagName, '%')
    )
WHERE 
    ta.TagRank <= 10 
ORDER BY 
    ta.PostCount DESC, pa.ViewCount DESC;


WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(c.Score, 0) AS CommentScore,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        p.OwnerUserId,
        p.Tags
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, SUM(Score) AS Score 
         FROM Comments 
         GROUP BY PostId) c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    INNER JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 10
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS Gold,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS Silver,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS Bronze
    FROM 
        Badges
    GROUP BY 
        UserId
)
SELECT 
    u.DisplayName,
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.CommentScore,
    COALESCE(b.Gold, 0) AS GoldBadges,
    COALESCE(b.Silver, 0) AS SilverBadges,
    COALESCE(b.Bronze, 0) AS BronzeBadges,
    t.TagName,
    t.TagCount
FROM 
    Users u
JOIN 
    RankedPosts r ON u.Id = r.OwnerUserId
LEFT JOIN 
    UserBadges b ON u.Id = b.UserId
JOIN 
    PopularTags t ON t.TagName = SUBSTRING_INDEX(SUBSTRING_INDEX(r.Tags, '><', numbers.n), '><', -1)
WHERE 
    r.PostRank <= 3
ORDER BY 
    r.Score DESC, b.Gold DESC, b.Silver DESC
LIMIT 50;

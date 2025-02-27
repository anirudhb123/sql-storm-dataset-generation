
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0
), UserBadges AS (
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
), PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '<>', n.n), '<>', -1) AS Tag
    FROM 
        Posts 
    JOIN 
        (SELECT a.N + 1 n FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                                    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a 
         CROSS JOIN (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                     UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b) n 
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '<>', '')) >= n.n - 1
    WHERE 
        PostTypeId = 1 AND Tags IS NOT NULL
), TagPopularity AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        PopularTags
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 5
)
SELECT 
    up.DisplayName AS UserDisplayName,
    r.Title AS TopPostTitle,
    r.CreationDate AS PostCreationDate,
    r.Score AS PostScore,
    tb.Tag AS PopularTag,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges
FROM 
    RankedPosts r
JOIN 
    Users up ON r.OwnerUserId = up.Id
JOIN 
    UserBadges ub ON up.Id = ub.UserId
CROSS JOIN 
    TagPopularity tb
WHERE 
    r.rn = 1
ORDER BY 
    r.Score DESC, 
    r.CreationDate DESC;

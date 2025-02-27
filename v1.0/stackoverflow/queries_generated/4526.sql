WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.Score IS NOT NULL
),
PopularTags AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(Tags, '><')) AS TagValue
    FROM 
        Posts
    WHERE 
        CreationDate >= NOW() - INTERVAL '30 days'
),
TagCounts AS (
    SELECT 
        TagValue,
        COUNT(*) AS TagUsage
    FROM 
        PopularTags
    GROUP BY 
        TagValue
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    tc.TagValue,
    tc.TagUsage
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN 
    TagCounts tc ON tc.TagValue IN (SELECT UNNEST(STRING_TO_ARRAY(rp.Tags, '><')))
WHERE 
    rp.ScoreRank <= 5
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;

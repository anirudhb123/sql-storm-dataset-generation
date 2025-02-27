WITH UserBadges AS (
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
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        COUNT(DISTINCT p.OwnerUserId) AS UserCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 10
),
HighScorePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.Score > 10
    ORDER BY 
        p.Score DESC
    LIMIT 5
)
SELECT 
    ub.UserId,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    pt.TagName,
    pt.PostCount,
    pt.UserCount,
    hsp.PostId,
    hsp.Title,
    hsp.Score AS HighScore,
    hsp.ViewCount,
    hsp.OwnerDisplayName,
    hsp.OwnerReputation
FROM 
    UserBadges ub
CROSS JOIN 
    PopularTags pt
CROSS JOIN 
    HighScorePosts hsp
ORDER BY 
    ub.BadgeCount DESC, 
    pt.PostCount DESC, 
    hsp.Score DESC;

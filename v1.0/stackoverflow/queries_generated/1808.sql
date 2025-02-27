WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS Owner,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.Score > 0
),
FilteredBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Class = 1 -- Gold badges
    GROUP BY 
        b.UserId
),
PopularTags AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><')) AS Tag
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL
),
TagStats AS (
    SELECT 
        t.Tag,
        COUNT(*) AS TagCount 
    FROM 
        PopularTags t
    GROUP BY 
        t.Tag
    HAVING 
        COUNT(*) > 5
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.Owner,
    COALESCE(b.BadgeCount, 0) AS GoldBadgeCount,
    COALESCE(b.BadgeNames, 'None') AS GoldBadges,
    ts.Tag,
    ts.TagCount
FROM 
    RankedPosts rp
LEFT JOIN 
    FilteredBadges b ON rp.Owner = b.UserId
LEFT JOIN 
    TagStats ts ON rp.Tags LIKE '%' || ts.Tag || '%'
WHERE 
    rp.PostRank = 1 -- Only top scored post for each user
    AND rp.CreationDate >= NOW() - INTERVAL '1 year'
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;

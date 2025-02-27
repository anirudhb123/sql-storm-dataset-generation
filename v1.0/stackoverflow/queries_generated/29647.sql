WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        pt.Name AS PostType,
        ROW_NUMBER() OVER (PARTITION BY pt.Id ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TagOccurrences AS (
    SELECT 
        UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><')) AS Tag,
        COUNT(*) as OccurrenceCount
    FROM 
        Posts 
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tag
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
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate,
    rp.PostType,
    TO_CHAR(rp.CreationDate, 'YYYY-MM-DD') AS CreationDateFormatted,
    SUM(CASE WHEN TO_CHAR(rp.CreationDate, 'MM') = '12' THEN 1 ELSE 0 END) AS DecemberPosts,
    TO_CHAR(MAX(b.CreationDate), 'YYYY-MM-DD') AS LastBadgeDate,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    STRING_AGG(DISTINCT to_char(occ.Tag), ', ') AS RelatedTags
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ub.UserId)
LEFT JOIN 
    TagOccurrences occ ON occ.OccurrenceCount > 0
WHERE 
    rp.Rank <= 5
GROUP BY 
    rp.PostId, rp.Title, rp.ViewCount, rp.CreationDate, rp.PostType, ub.BadgeCount, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges
ORDER BY 
    rp.ViewCount DESC;

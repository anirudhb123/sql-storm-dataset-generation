WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews,
        COALESCE(NULLIF(UPPER(p.Title), ''), '<untitled>') AS TitleCase,
        ARRAY_LENGTH(STRING_TO_ARRAY(p.Tags, '>'), 1) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.ViewCount IS NOT NULL
),
RecentActivity AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        ph.UserId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RecentRank
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '30 days'
        AND ph.PostHistoryTypeId IN (10, 11, 12, 19, 20)  -- focusing on close/open/delete/reopen actions
),
UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS BadgeCount, 
        MAX(b.Class) AS HighestBadgeClass
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
    rb.UserDisplayName AS OwnerDisplayName,
    ra.CreationDate AS RecentActionDate,
    CASE 
        WHEN rb.BadgeCount > 0 THEN 'Yes' ELSE 'No' END AS HasBadges,
    CASE 
        WHEN rp.RankByViews <= 3 THEN 'Top Post' 
        WHEN rp.TagCount = 1 THEN 'Single Tag' 
        ELSE 'Regular Post' END AS PostCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    Users rb ON rp.OwnerUserId = rb.Id
LEFT JOIN 
    RecentActivity ra ON rp.PostId = ra.PostId AND ra.RecentRank = 1
LEFT JOIN 
    UserBadges ub ON rb.Id = ub.UserId
WHERE 
    rp.RankByViews <= 5
    AND (ra.CreationDate IS NULL OR ra.CreationDate >= NOW() - INTERVAL '15 days')
ORDER BY 
    rp.ViewCount DESC,
    rp.TagCount DESC,
    rp.CreationDate DESC;

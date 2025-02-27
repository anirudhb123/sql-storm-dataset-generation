WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
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
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  -- Title and body edits
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Title,
    p.ViewCount,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    ub.BadgeCount,
    phc.EditCount,
    phc.LastEditDate,
    CASE 
        WHEN phc.EditCount > 0 THEN 'Edited'
        ELSE 'Not Edited'
    END AS EditStatus
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostHistoryCounts phc ON p.Id = phc.PostId
WHERE 
    p.Score > 0
    AND p.ViewCount IS NOT NULL
    AND (ub.BadgeCount IS NULL OR ub.BadgeCount > 0)
ORDER BY 
    p.ViewCount DESC, 
    p.CreationDate DESC
FETCH FIRST 100 ROWS ONLY;

-- Additionally fetching posts with links and correlated subquery for related posts
SELECT 
    p.Title AS OriginalPostTitle,
    pl.RelatedPostId,
    rp.Title AS RelatedPostTitle
FROM 
    PostLinks pl
JOIN 
    Posts p ON pl.PostId = p.Id
JOIN 
    Posts rp ON pl.RelatedPostId = rp.Id
WHERE 
    p.ViewCount > (SELECT AVG(ViewCount) FROM Posts)
    AND p.CreationDate >= (NOW() - INTERVAL '6 months')
ORDER BY 
    p.CreationDate DESC;


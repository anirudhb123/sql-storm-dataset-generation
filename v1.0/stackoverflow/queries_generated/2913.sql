WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        p.Title,
        p.OwnerUserId,
        ph.UserDisplayName AS CloserName,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.UserId ORDER BY ph.CreationDate DESC) AS CloseRank
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId = 10
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
    p.Id AS PostId,
    p.Title,
    p.ViewCount,
    COALESCE(b.BadgeCount, 0) AS TotalBadges,
    COALESCE(b.GoldBadges, 0) AS TotalGoldBadges,
    COALESCE(b.SilverBadges, 0) AS TotalSilverBadges,
    COALESCE(b.BronzeBadges, 0) AS TotalBronzeBadges,
    cp.ClosedDate AS LastClosedDate,
    cp.ClosingUser AS CloserName,
    CASE 
        WHEN rp.Rank = 1 THEN 'Latest Post'
        ELSE 'Older Post'
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    Posts p ON rp.Id = p.Id
LEFT JOIN 
    UserBadges b ON p.OwnerUserId = b.UserId
LEFT JOIN 
    ClosedPosts cp ON p.Id = cp.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    p.ViewCount DESC, 
    p.CreationDate ASC;

WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions only
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate,
        STRING_AGG(DISTINCT ctr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ctr ON ph.Comment::int = ctr.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId
)
SELECT 
    up.DisplayName AS UserDisplayName,
    up.Reputation,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    COALESCE(rp.ViewCount, 0) AS ViewCount,
    COALESCE(rp.Score, 0) AS Score,
    COALESCE(cb.LastClosedDate, NULL) AS LastClosedDate,
    COALESCE(cb.CloseReasons, 'None') AS CloseReasons,
    ub.BadgeCount,
    ub.BadgeNames
FROM 
    Users up
LEFT JOIN 
    RankedPosts rp ON up.Id = rp.OwnerUserId AND rp.RankByViews = 1
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
LEFT JOIN 
    ClosedPosts cb ON cb.PostId = rp.PostId
WHERE 
    up.Reputation IS NOT NULL AND up.Reputation > 100 -- Users with reputation > 100
ORDER BY 
    up.Reputation DESC, 
    COALESCE(rp.ViewCount, 0) DESC;

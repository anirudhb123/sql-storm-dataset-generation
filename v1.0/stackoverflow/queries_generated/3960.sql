WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY p.Id) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY p.Id) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        b.UserId, 
        ARRAY_AGG(b.Name) AS BadgeNames,
        COUNT(*) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(*) FILTER (WHERE b.Class = 2) AS SilverBadges
    FROM 
        Badges b
    GROUP BY b.UserId
),
ClosedPostReasons AS (
    SELECT 
        ph.PostId, 
        ARRAY_AGG(CASE WHEN ph.PostHistoryTypeId = 10 THEN cr.Name END) AS CloseReasons
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY ph.PostId
)
SELECT 
    u.DisplayName,
    up.BadgeNames,
    rp.Title,
    rp.ViewCount,
    rp.Upvotes,
    rp.Downvotes,
    COALESCE(cpr.CloseReasons, '{}') AS CloseReasons
FROM 
    Users u
JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
LEFT JOIN 
    UserBadges up ON u.Id = up.UserId
LEFT JOIN 
    ClosedPostReasons cpr ON rp.Id = cpr.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.ViewCount DESC
LIMIT 100;

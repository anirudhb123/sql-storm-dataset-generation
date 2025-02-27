WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT c.Name, ', ') AS CloseReasons,
        COUNT(*) AS TotalCloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes c ON ph.Comment::int = c.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- filtered for close/reopen actions
    GROUP BY 
        ph.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
AggregatedUserData AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    cp.CloseReasons,
    COALESCE(au.UserId, -1) AS UserId,
    au.DisplayName,
    au.GoldBadges,
    au.SilverBadges,
    au.BronzeBadges,
    COALESCE(au.TotalBounty, 0) AS TotalBounty
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    Posts p ON p.AcceptedAnswerId = rp.PostId 
LEFT JOIN 
    AggregatedUserData au ON p.OwnerUserId = au.UserId
WHERE 
    rp.RankScore <= 5 
    AND (rp.Score > 0 OR cp.TotalCloseReasons > 0)
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
LIMIT 100;

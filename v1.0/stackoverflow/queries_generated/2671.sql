WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(b.Class = 1)::int, 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2)::int, 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3)::int, 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.AnswerCount,
    rp.ViewCount
FROM 
    UserStats us
JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId
WHERE 
    rp.PostRank = 1
ORDER BY 
    us.Reputation DESC, rp.Score DESC
LIMIT 10;

WITH PostHistoryDetail AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        ph.Comment,
        STRING_AGG(DISTINCT cht.Name, ', ') AS CloseReasons,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes cht ON ph.Comment::int = cht.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '6 months'
    GROUP BY 
        ph.PostId, ph.UserId, ph.CreationDate, ph.PostHistoryTypeId
)
SELECT 
    p.Title,
    p.CreationDate,
    COALESCE(pv.ViewCount, 0) AS TotalViews,
    COALESCE(h.CloseReasons, 'No Close Reasons') AS CloseReasonDetails,
    COALESCE(h.CloseReopenCount, 0) AS CloseReopenActions
FROM 
    Posts p
LEFT JOIN 
    PostHistoryDetail h ON p.Id = h.PostId
LEFT JOIN 
    (SELECT PostId, SUM(ViewCount) AS ViewCount FROM Posts GROUP BY PostId) pv ON p.Id = pv.PostId
WHERE 
    COALESCE(h.CloseReopenCount, 0) > 0 OR h.CloseReasons IS NULL
ORDER BY 
    p.CreationDate DESC
LIMIT 20;

WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
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
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS LastReopenedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
PostScores AS (
    SELECT 
        p.Id,
        p.Score,
        COALESCE(E.EditCount, 0) AS EditCount,
        COALESCE(E.LastClosedDate, '1970-01-01'::timestamp) AS LastClosedDate,
        COALESCE(E.LastReopenedDate, '1970-01-01'::timestamp) AS LastReopenedDate
    FROM 
        Posts p
    LEFT JOIN 
        PostHistorySummary E ON p.Id = E.PostId
)
SELECT 
    up.UserId,
    u.DisplayName,
    SUM(ps.Score) AS TotalScore,
    SUM(DISTINCT CASE WHEN ps.EditCount > 0 THEN 1 ELSE 0 END) AS ActiveEditedPosts,
    MAX(ps.LastClosedDate) AS LastClosedPostDate,
    MAX(ps.LastReopenedDate) AS LastReopenedPostDate,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges
FROM 
    UserBadges ub
JOIN 
    Users u ON ub.UserId = u.Id
JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
JOIN 
    PostScores ps ON rp.Id = ps.Id
LEFT JOIN 
    Posts p ON ps.Id = p.Id
WHERE 
    (ub.BadgeCount > 1 OR rp.RecentPostRank = 1)
    AND (COALESCE(ps.LastClosedDate, '1970-01-01'::timestamp) < COALESCE(ps.LastReopenedDate, '1970-01-01'::timestamp)
         OR COALESCE(ps.LastClosedDate, '1970-01-01'::timestamp) IS NULL)
GROUP BY 
    up.UserId, u.DisplayName, ub.BadgeCount, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges
ORDER BY 
    TotalScore DESC
LIMIT 10;

WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '365 days'
),
PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(DISTINCT b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(DISTINCT b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges,
        AVG(u.Reputation) AS AvgReputation,
        MAX(ph.CreationDate) AS LastActivity
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    LEFT JOIN 
        Users u ON u.Id = p.OwnerUserId
    LEFT JOIN 
        RecursivePostHistory rph ON rph.PostId = p.Id AND rph.HistoryRank = 1
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '730 days' -- within the last two years
    GROUP BY 
        p.Id, p.Title, p.ViewCount
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        MAX(CASE WHEN ph.Comment IS NOT NULL THEN ph.Comment ELSE 'N/A' END) AS LatestCloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY 
        ph.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.CommentCount,
    ps.GoldBadges,
    ps.SilverBadges,
    ps.BronzeBadges,
    ps.AvgReputation,
    ps.LastActivity,
    cp.CloseCount,
    cp.LatestCloseReason,
    CASE 
        WHEN cp.CloseCount IS NOT NULL THEN 'Closed' 
        ELSE 'Open' 
    END AS PostStatus,
    CASE 
        WHEN MAX(v.BountyAmount) IS NULL THEN 'No Bounty'
        ELSE CONCAT('Bounty of ', MAX(v.BountyAmount), ' points')
    END AS BountyStatus
FROM 
    PostSummary ps
LEFT JOIN 
    ClosedPosts cp ON ps.PostId = cp.PostId
LEFT JOIN 
    Votes v ON v.PostId = ps.PostId AND v.VoteTypeId IN (8, 9) -- BountyStart, BountyClose
GROUP BY 
    ps.PostId, ps.Title, ps.ViewCount, ps.CommentCount, ps.GoldBadges, ps.SilverBadges, 
    ps.BronzeBadges, ps.AvgReputation, ps.LastActivity, cp.CloseCount, cp.LatestCloseReason
ORDER BY 
    ps.ViewCount DESC, ps.LastActivity DESC
LIMIT 100;

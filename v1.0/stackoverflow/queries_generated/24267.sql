WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'
        AND p.Score IS NOT NULL
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
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenedDate,
        ARRAY_AGG(DISTINCT c.Text) AS CloseReasons
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes cr ON ph.Comment::text::int = cr.Id
    LEFT JOIN 
        Comments c ON c.PostId = ph.PostId
    GROUP BY 
        ph.PostId
)

SELECT 
    u.DisplayName,
    COUNT(DISTINCT p.PostId) AS PostCount,
    COALESCE(SUM(pb.BadgeCount), 0) AS TotalBadges,
    PHD.ClosedDate,
    PHD.ReopenedDate,
    PHD.CloseReasons,
    RANK() OVER (ORDER BY COUNT(DISTINCT p.PostId) DESC) AS UserRank,
    R.Score AS HighestScorePost
FROM 
    Users u
LEFT JOIN 
    RankedPosts R ON u.Id = R.OwnerUserId AND R.RankByScore = 1
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    UserBadges pb ON u.Id = pb.UserId
LEFT JOIN 
    PostHistoryDetails PHD ON p.Id = PHD.PostId
WHERE 
    u.Reputation > 1000 
GROUP BY 
    u.DisplayName, PHD.ClosedDate, PHD.ReopenedDate, PHD.CloseReasons
ORDER BY 
    UserRank;

This query gathers various insights about users who have posted questions in the last year, linking their performance with their badge accumulation while factoring in post closure events and ranks them based on their activity. It utilizes CTEs for encapsulating logic, employs window functions for ranking, and handles NULL logic appropriately. The use of arrays to collect close reasons adds an interesting touch to the data presentation.

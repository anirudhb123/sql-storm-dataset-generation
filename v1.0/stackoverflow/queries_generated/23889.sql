WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        p.OwnerUserId,
        COALESCE(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags)-2), 'No Tags') AS CleanTags
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.Views,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN COALESCE(b.Class, 0) = 1 THEN 1 ELSE 0 END) AS GoldBadges
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
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.CreationDate END) AS ClosedOrReopenedAt,
        ARRAY_AGG(DISTINCT ch.Name) FILTER (WHERE ph.PostHistoryTypeId = 10) AS CloseReasons
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes ch ON ph.Comment::int = ch.Id
    GROUP BY 
        ph.PostId
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CleanTags,
        us.Reputation,
        ps.ClosedOrReopenedAt,
        array_length(ps.CloseReasons, 1) AS CloseReasonCount,
        CASE WHEN rp.ViewCount > 1000 THEN 'High Traffic' ELSE 'Normal Traffic' END AS TrafficLabel,
        RANK() OVER (ORDER BY us.Views DESC, rp.ViewCount DESC) AS ViewRank
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON rp.OwnerUserId = us.UserId
    LEFT JOIN 
        PostHistoryDetails ps ON rp.PostId = ps.PostId
    WHERE 
        rp.Rank <= 5
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.CleanTags,
    pp.Reputation,
    pp.CloseReasonCount,
    pp.ClosedOrReopenedAt,
    pp.TrafficLabel,
    CASE 
        WHEN pp.CloseReasonCount IS NOT NULL AND pp.ClosedOrReopenedAt IS NOT NULL 
        THEN 'Closed or Reopened'
        ELSE 'Active'
    END AS PostStatus
FROM 
    PopularPosts pp
WHERE 
    pp.ViewRank <= 10
ORDER BY 
    pp.Reputation DESC,
    pp.CloseReasonCount ASC
LIMIT 25;

This query performs various operations including CTEs for ranking posts and gathering user badges, uses window functions for ranking and traffic labeling, incorporates conditional logic with `CASE` statements, and handles NULL values using `COALESCE`. A thorough aggregation is utilized with string functions and outer joins to triumphantly weave through opaque and convoluted SQL semantics.

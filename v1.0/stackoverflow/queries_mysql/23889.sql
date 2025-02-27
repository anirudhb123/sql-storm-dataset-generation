
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        @row_number := IF(@prev_post_type_id = p.PostTypeId, @row_number + 1, 1) AS Rank,
        @prev_post_type_id := p.PostTypeId,
        p.OwnerUserId,
        COALESCE(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), 'No Tags') AS CleanTags
    FROM 
        Posts p,
        (SELECT @row_number := 0, @prev_post_type_id := NULL) r
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    ORDER BY 
        p.PostTypeId, p.Score DESC, p.CreationDate DESC
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
        u.Id, u.Reputation, u.Views
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.CreationDate END) AS ClosedOrReopenedAt,
        GROUP_CONCAT(DISTINCT ch.Name) AS CloseReasons
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes ch ON ph.Comment = CAST(ch.Id AS CHAR)
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
        LENGTH(ps.CloseReasons) - LENGTH(REPLACE(ps.CloseReasons, ',', '')) + 1 AS CloseReasonCount,
        CASE WHEN rp.ViewCount > 1000 THEN 'High Traffic' ELSE 'Normal Traffic' END AS TrafficLabel,
        @view_rank := IF(@prev_views = us.Views, @view_rank + 1, 1) AS ViewRank,
        @prev_views := us.Views
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON rp.OwnerUserId = us.UserId,
        (SELECT @view_rank := 0, @prev_views := NULL) vr
    WHERE 
        rp.Rank <= 5
    ORDER BY 
        us.Views DESC, rp.ViewCount DESC
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

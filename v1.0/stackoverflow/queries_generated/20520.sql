WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreatedDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankView
    FROM 
        Posts p
    WHERE 
        p.Score IS NOT NULL
        AND p.ViewCount > 100
),
BadgedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount 
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
    HAVING 
        COUNT(b.Id) > 5
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT ph.UserId) AS CloseVoteCount,
        MAX(ph.CreationDate) AS LastCloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        COALESCE(cp.CloseVoteCount, 0) AS CloseVoteCount,
        cp.LastCloseDate,
        bu.BadgeCount,
        CASE 
            WHEN rp.RankScore <= 3 THEN 'TopPerformer'
            ELSE 'RegularPost'
        END AS PerformanceCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    LEFT JOIN 
        BadgedUsers bu ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = bu.UserId)
),
FinalPostStats AS (
    SELECT 
        ps.*,
        CASE 
            WHEN ps.CloseVoteCount > 0 THEN 'Closed'
            ELSE 'Open'
        END AS PostStatus,
        COALESCE(ps.BadgeCount > 10, FALSE) AS HasManyBadges,
        (SELECT STRING_AGG(Name, ', ') 
         FROM PostHistoryTypes pht 
         WHERE pht.Id IN (SELECT DISTINCT PostHistoryTypeId FROM PostHistory WHERE PostId = ps.PostId)) AS HistoryTypes
    FROM 
        PostStatistics ps
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.CloseVoteCount,
    ps.LastCloseDate,
    ps.PerformanceCategory,
    ps.PostStatus,
    ps.HasManyBadges,
    ps.HistoryTypes
FROM 
    FinalPostStats ps
WHERE 
    ps.Score > 0
    AND ps.ViewCount > 500
    AND (ps.CloseVoteCount IS NULL OR ps.CloseVoteCount < 2) 
ORDER BY 
    ps.Score DESC, ps.CloseVoteCount ASC;

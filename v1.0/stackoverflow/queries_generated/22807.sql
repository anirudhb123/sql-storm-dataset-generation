WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '1 year') 
        AND p.ViewCount > 100
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistoryAggregated AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        ISNULL(pa.Edits, 0) AS EditCount,
        u.Reputation,
        ub.BadgeCount,
        ub.BadgeNames
    FROM 
        RankedPosts rp
    LEFT JOIN PostHistoryAggregated pa ON rp.PostId = pa.PostId
    JOIN Users u ON rp.PostId IN (
        SELECT DISTINCT p.OwnerUserId FROM Posts p WHERE p.Id = rp.PostId
    )
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        STRING_AGG(ct.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN CloseReasonTypes ct ON ph.Comment::int = ct.Id 
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
)
SELECT 
    pd.Title,
    pd.Score,
    pd.ViewCount,
    pd.EditCount,
    pd.Reputation,
    pd.BadgeCount,
    pd.BadgeNames,
    COALESCE(cp.CloseReasons, 'No close reasons') AS CloseReasons
FROM 
    PostDetails pd
LEFT JOIN ClosedPosts cp ON pd.PostId = cp.PostId
WHERE 
    pd.Rank <= 10
    AND pd.Reputation >= 100
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;

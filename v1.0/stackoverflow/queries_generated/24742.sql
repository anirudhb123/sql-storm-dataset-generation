WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        CASE 
            WHEN u.Reputation IS NULL THEN 'Unknown'
            WHEN u.Reputation >= 1000 THEN 'High'
            WHEN u.Reputation >= 100 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationCategory
    FROM 
        Users u
),

ClosedPosts AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName,
    u.Reputation,
    ur.ReputationCategory,
    COALESCE(cp.CloseReasons, 'No close reasons') AS CloseReasons,
    COALESCE(cp.CloseCount, 0) AS CloseCount
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserReputation ur ON u.Id = ur.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.ScoreRank <= 5 AND
    (rp.ViewCount > 100 OR ur.ReputationCategory = 'High')
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;

This query performs several complex operations:
- **Common Table Expressions (CTEs)** for `RankedPosts`, `UserReputation`, and `ClosedPosts`.
- Use of **window functions** in `RankedPosts` to rank posts based on their score.
- Use of **string aggregation** to retrieve multiple close reasons for each post.
- Pruned `WHERE` clause that filters ranked posts with a top score, or posts viewed over a threshold, alongside user reputation logic.
- Final select combines attributes from several joined tables and handles potential `NULL` values appropriately.

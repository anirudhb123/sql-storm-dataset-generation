WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
        CASE 
            WHEN p.Score > 100 THEN 'High Score'
            WHEN p.Score BETWEEN 50 AND 100 THEN 'Medium Score'
            ELSE 'Low Score'
        END AS ScoreCategory
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
), 
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        PERCENT_RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
), 
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.CreationDate,
    rp.Rank,
    rp.ScoreCategory,
    COALESCE(cp.CloseCount, 0) AS NumberOfCloses,
    u.DisplayName AS UserName,
    u.Reputation,
    u.ReputationRank,
    CASE 
        WHEN u.Reputation < 100 THEN 'Newbie'
        WHEN u.Reputation BETWEEN 100 AND 500 THEN 'Contributor'
        ELSE 'Expert'
    END AS UserLevel
FROM 
    RankedPosts rp
LEFT JOIN 
    PostLinks pl ON pl.PostId = rp.PostId
LEFT JOIN 
    ClosedPosts cp ON cp.PostId = rp.PostId
LEFT JOIN 
    Users u ON u.Id = rp.PostId -- Assuming owners can be identified by PostId (need a valid relation)
WHERE 
    rp.Rank <= 10
AND 
    (rp.ScoreCategory = 'High Score' OR rp.CloseCount IS NULL)
ORDER BY 
    rp.Score DESC, 
    rp.NumberOfCloses ASC;

-- This query combines ranked posts with user reputation and closed post counts.
-- It employs window functions, CTEs, and intricate conditions to highlight active and influential posts with user activity. 

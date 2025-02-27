WITH RecursivePostHierarchy AS (
    -- CTE to get recursive parent-child relationships for posts
    SELECT 
        Id,
        ParentId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        0 AS Level
    FROM Posts
    WHERE ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy rph ON p.ParentId = rph.Id
),
UserStatistics AS (
    -- CTE to aggregate user statistics
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
PostHistoryDetails AS (
    -- CTE to get post history details along with close reasons
    SELECT 
        p.Id AS PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ph.Comment,
        ph.UserDisplayName AS Editor,
        CASE
            WHEN ph.PostHistoryTypeId = 10 THEN 
                (SELECT cr.Name FROM CloseReasonTypes cr WHERE cr.Id = CAST(ph.Comment AS INT))
            ELSE 
                NULL
        END AS CloseReason
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
)
SELECT 
    rp.Id AS PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    COALESCE(us.PostCount, 0) AS UserPostCount,
    COALESCE(us.TotalScore, 0) AS UserTotalScore,
    COALESCE(us.AvgViewCount, 0) AS UserAvgViewCount,
    ph.PostHistoryTypeId,
    ph.HistoryDate,
    ph.Editor,
    ph.CloseReason
FROM RecursivePostHierarchy rp
LEFT JOIN UserStatistics us ON rp.OwnerUserId = us.UserId
LEFT JOIN PostHistoryDetails ph ON rp.Id = ph.PostId
WHERE ph.PostHistoryTypeId IS NOT NULL -- Example filtering based on post history type
ORDER BY rp.ViewCount DESC, rp.Title ASC; -- Example ordering

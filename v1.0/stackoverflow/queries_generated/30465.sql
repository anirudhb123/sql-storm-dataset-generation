WITH RecursivePosts AS (
    -- Recursive CTE to find all answers associated with questions and their related posts
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        Level + 1
    FROM Posts p
    INNER JOIN RecursivePosts rp ON p.ParentId = rp.PostId
    WHERE p.PostTypeId = 2 -- Answers
),
PostViews AS (
    -- Aggregate view data based on post ownership and type
    SELECT 
        rp.PostId,
        COUNT(rp.PostId) AS TotalViews,
        MAX(u.Reputation) AS MaxReputation
    FROM RecursivePosts rp
    INNER JOIN Users u ON rp.OwnerUserId = u.Id
    GROUP BY rp.PostId
),
CloseReasonCounts AS (
    -- Count the number of close reasons applied to posts
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseReasons
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY ph.PostId
),
PostStatistics AS (
    -- Combine views and close reasons
    SELECT 
        pv.PostId,
        pv.TotalViews,
        COALESCE(crc.CloseReasons, 0) AS CloseReasons
    FROM PostViews pv
    LEFT JOIN CloseReasonCounts crc ON pv.PostId = crc.PostId
),
TopUsers AS (
    -- Identify top users by number of posts created
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(u.Reputation) AS TotalReputation
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
    ORDER BY PostCount DESC
    LIMIT 10
)
SELECT 
    ps.PostId,
    ps.TotalViews,
    ps.CloseReasons,
    tu.UserId,
    tu.DisplayName,
    tu.PostCount,
    tu.TotalReputation
FROM PostStatistics ps
INNER JOIN RecursivePosts rp ON ps.PostId = rp.PostId
INNER JOIN TopUsers tu ON rp.OwnerUserId = tu.UserId
WHERE ps.TotalViews IS NOT NULL
ORDER BY ps.TotalViews DESC, ps.CloseReasons ASC;

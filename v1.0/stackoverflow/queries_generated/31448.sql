WITH RecursivePostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Starting from Questions

    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.OwnerUserId,
        a.Title,
        a.CreationDate,
        a.Score,
        Level + 1
    FROM Posts a
    INNER JOIN Posts q ON a.ParentId = q.Id
    WHERE q.PostTypeId = 1
), TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        SUM(a.Score) AS TotalScore,
        COUNT(p.Id) AS TotalPosts
    FROM Users u
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN Votes v ON v.UserId = u.Id
    LEFT JOIN Posts a ON a.AcceptedAnswerId = p.Id
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName
), UserRankedPosts AS (
    SELECT 
        ts.PostId,
        ts.OwnerUserId,
        ts.Title,
        ts.CreationDate,
        ts.Score,
        tu.DisplayName,
        RANK() OVER (PARTITION BY tu.UserId ORDER BY ts.Score DESC) AS Rank
    FROM RecursivePostStats ts
    INNER JOIN TopUsers tu ON ts.OwnerUserId = tu.UserId
), ClosedPostStats AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        MIN(ph.CreationDate) AS FirstClosedDate,
        COUNT(*) AS ClosureCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY ph.PostId
), FinalStats AS (
    SELECT 
        up.PostId,
        up.Title,
        up.DisplayName,
        up.CreationDate,
        COALESCE(cps.ClosureCount, 0) AS ClosureCount,
        COALESCE(cps.FirstClosedDate, '1970-01-01'::timestamp) AS FirstClosedDate,
        up.Score,
        up.Rank
    FROM UserRankedPosts up
    LEFT JOIN ClosedPostStats cps ON up.PostId = cps.PostId
)
SELECT 
    Title,
    DisplayName,
    CreationDate,
    Score,
    ClosureCount,
    FirstClosedDate
FROM FinalStats
WHERE Rank <= 5 -- Top 5 posts per user
ORDER BY Score DESC, DisplayName;

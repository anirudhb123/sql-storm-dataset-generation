WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        1 as Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Start with top-level questions

    UNION ALL 

    SELECT 
        p2.Id,
        p2.Title,
        p2.ParentId,
        ph.Level + 1
    FROM Posts p2
    INNER JOIN PostHierarchy ph ON p2.ParentId = ph.Id
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
RecentActivity AS (
    SELECT 
        c.UserId,
        COUNT(c.Id) AS TotalComments,
        COUNT(DISTINCT p.Id) AS TotalCommentedPosts,
        MAX(c.CreationDate) AS LastCommentDate
    FROM Comments c
    LEFT JOIN Posts p ON c.PostId = p.Id
    GROUP BY c.UserId
),
PostHistoryAggregated AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS TotalCloseReopen,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 24 THEN 1 END) AS TotalEdits
    FROM PostHistory ph
    GROUP BY ph.PostId
)
SELECT 
    u.DisplayName,
    ups.TotalPosts,
    ups.TotalAnswers,
    ups.TotalScore,
    ra.TotalComments,
    ra.TotalCommentedPosts,
    PH.TotalCloseReopen,
    PH.TotalEdits,
    ph.Id AS PostId,
    ph.Title,
    ph.Level
FROM PostHierarchy ph
JOIN UserPostStats ups ON ph.Id = ups.UserId
JOIN RecentActivity ra ON ra.UserId = ups.UserId
LEFT JOIN PostHistoryAggregated PH ON ph.Id = PH.PostId
ORDER BY ups.TotalScore DESC, ra.LastCommentDate DESC
LIMIT 100;

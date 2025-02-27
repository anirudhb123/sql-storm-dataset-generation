WITH RecursivePostHierarchy AS (
    SELECT Id, Title, ParentId, 1 AS Level
    FROM Posts
    WHERE ParentId IS NULL

    UNION ALL

    SELECT p.Id, p.Title, p.ParentId, Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy rph ON p.ParentId = rph.Id
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        AVG(p.Score) AS AveragePostScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment AS CloseReason,
        ph.CreationDate AS CloseDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
),
HighScoringUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.PostCount,
        ua.UpvoteCount,
        ua.DownvoteCount,
        ua.AveragePostScore,
        RANK() OVER (ORDER BY ua.AveragePostScore DESC) AS ScoreRank
    FROM UserActivity ua
    WHERE ua.PostCount > 0
)

SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    COALESCE(cl.CloseReason, 'Not Closed') AS CloseReason,
    hp.Level AS PostHierarchyLevel,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS TotalVotes,
    AVG(p.Score) AS AvgScore
FROM Users u
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN Votes v ON p.Id = v.PostId
LEFT JOIN ClosedPosts cl ON p.Id = cl.PostId
LEFT JOIN RecursivePostHierarchy hp ON p.Id = hp.Id
LEFT JOIN HighScoringUsers hsu ON u.Id = hsu.UserId
WHERE 
    (u.Location LIKE '%USA%' OR u.Reputation > 500)
    AND (p.CreationDate BETWEEN NOW() - INTERVAL '1 year' AND NOW())
GROUP BY u.DisplayName, u.Reputation, cl.CloseReason, hp.Level
HAVING COUNT(DISTINCT p.Id) > 5
ORDER BY AvgScore DESC, u.DisplayName;

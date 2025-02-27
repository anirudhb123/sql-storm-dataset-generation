WITH RecursivePostHierarchy AS (
    SELECT Id, Title, ParentId, OwnerUserId, CreationDate, 1 AS Level
    FROM Posts
    WHERE ParentId IS NULL

    UNION ALL

    SELECT p.Id, p.Title, p.ParentId, p.OwnerUserId, p.CreationDate, Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy rph ON p.ParentId = rph.Id
),
TopUsers AS (
    SELECT
        u.Id,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM Users u
),
UserWithBadges AS (
    SELECT
        ub.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM Badges b
    JOIN Users ub ON b.UserId = ub.Id
    WHERE b.Class = 1 -- Only Gold Badges
    GROUP BY ub.UserId
),
PostStatistics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Owner,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS EditCount
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE p.CreationDate >= '2023-01-01'
    GROUP BY p.Id, u.DisplayName, v.UpVotes, v.DownVotes
),
ActivePostCounts AS (
    SELECT
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS ActivePostCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE p.CreationDate >= DATEADD(MONTH, -6, GETDATE())
    GROUP BY u.Id
)
SELECT
    pu.Id AS UserId,
    pu.DisplayName,
    pu.Reputation,
    COALESCE(badge.BadgeCount, 0) AS GoldBadges,
    COALESCE(apc.ActivePostCount, 0) AS ActivePosts,
    COUNT(DISTINCT ps.PostId) AS TotalPosts,
    SUM(ps.UpVotes) AS TotalUpVotes,
    SUM(ps.DownVotes) AS TotalDownVotes,
    SUM(ps.CommentCount) AS TotalComments,
    COUNT(DISTINCT ph.Id) AS TotalEdits
FROM TopUsers pu
LEFT JOIN UserWithBadges badge ON pu.Id = badge.UserId
LEFT JOIN ActivePostCounts apc ON pu.Id = apc.UserId
LEFT JOIN PostStatistics ps ON pu.Id = ps.Owner
LEFT JOIN PostHistory ph ON ps.PostId = ph.PostId
WHERE pu.Rank <= 50
GROUP BY pu.Id, pu.DisplayName, pu.Reputation, badge.BadgeCount, apc.ActivePostCount
ORDER BY pu.Reputation DESC;

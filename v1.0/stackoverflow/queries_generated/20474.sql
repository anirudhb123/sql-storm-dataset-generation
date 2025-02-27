WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountySpent,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId AND v.VoteTypeId = 8  -- Bounty Start votes
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2  -- Only Answers
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory ph
    WHERE ph.CreationDate >= NOW() - INTERVAL '3 months'
    GROUP BY ph.PostId, ph.PostHistoryTypeId
)
SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.Reputation,
    ur.TotalBountySpent,
    ur.BadgeCount,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.AnswerCount,
    rph.LastEditDate,
    rph.HistoryCount,
    CASE 
        WHEN ps.UserPostRank = 1 THEN 'Most Recent Post'
        ELSE NULL
    END AS PostRankStatus
FROM UserReputation ur
JOIN PostStatistics ps ON ur.UserId = ps.OwnerUserId
LEFT JOIN RecentPostHistory rph ON ps.PostId = rph.PostId 
WHERE ur.Reputation > 100 -- Only high reputation users
AND ps.CommentCount > 5 -- Posts with significant interactions
AND rph.HistoryCount > 1 -- Multiple history edits
ORDER BY ur.Reputation DESC, ps.ViewCount DESC
LIMIT 50;

-- Potential corner cases: 
-- Handles users with no bounties and badges, 
-- Posts with different interaction metrics filtering out those with low engagement,
-- Uses NULL handling to separate out ranks,
-- Employs window functions for relative rankings of posts by users.

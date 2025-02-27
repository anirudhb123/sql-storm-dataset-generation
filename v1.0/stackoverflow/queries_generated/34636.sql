WITH RECURSIVE UserReputation AS (
    SELECT u.Id, u.Reputation, u.DisplayName, 0 AS Level
    FROM Users u
    WHERE u.Reputation > 1000
    UNION ALL
    SELECT u.Id, u.Reputation, u.DisplayName, ur.Level + 1
    FROM Users u
    INNER JOIN UserReputation ur ON u.Reputation > ur.Reputation
    WHERE ur.Level < 5
),
PostReviewStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        AVG(v.BountyAmount) AS AvgBounty,
        COUNT(c.Id) AS CommentCount,
        MAX(p.LastActivityDate) AS LastActive
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY p.Id
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.VoteCount,
        ps.AvgBounty,
        ps.CommentCount,
        ps.LastActive,
        ROW_NUMBER() OVER (ORDER BY ps.VoteCount DESC) AS RowNum
    FROM PostReviewStats ps
    WHERE ps.VoteCount > 10
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    WHERE b.Class = 1 -- Only gold badges
    GROUP BY b.UserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    ur.Level,
    tp.PostId,
    tp.VoteCount,
    tp.AvgBounty,
    tp.CommentCount,
    ub.BadgeCount,
    ub.BadgeNames
FROM UserReputation ur
JOIN Users u ON ur.Id = u.Id
LEFT JOIN TopPosts tp ON u.Id = tp.PostId
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
WHERE u.Location IS NOT NULL
AND (ub.BadgeCount > 0 OR u.Reputation > 5000)
ORDER BY u.Reputation DESC, tp.VoteCount DESC
LIMIT 100;

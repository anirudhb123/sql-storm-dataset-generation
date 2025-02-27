-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    GROUP BY p.Id, p.PostTypeId, p.CreationDate, p.Score, p.ViewCount
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgeClass,
        MAX(u.CreationDate) AS AccountCreationDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation
)
SELECT 
    ps.PostId,
    ps.PostTypeId,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.VoteCount,
    us.UserId,
    us.Reputation,
    us.PostCount,
    us.TotalBadgeClass,
    us.AccountCreationDate
FROM PostStats ps
JOIN UserStats us ON ps.PostTypeId IN (1, 2)  -- Only for Questions and Answers
ORDER BY ps.ViewCount DESC, ps.Score DESC
LIMIT 100;  -- Limit to top 100 posts for benchmarking

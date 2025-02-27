WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounties,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    u.BadgeCount,
    u.TotalBounties,
    u.PostCount,
    u.CommentCount,
    p.PostId,
    p.Title,
    p.ViewCount,
    p.Score,
    p.CreationDate,
    p.CommentCount AS PostCommentCount,
    p.VoteCount
FROM UserStats u
JOIN PostStats p ON u.PostCount > 0
ORDER BY u.Reputation DESC, p.ViewCount DESC
LIMIT 100;

-- Performance benchmarking SQL query for Stack Overflow schema

WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        MAX(b.CreationDate) AS LastCommentDate
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    GROUP BY p.Id, p.Title, p.Score, p.ViewCount
)
SELECT 
    u.UserId,
    u.Reputation,
    u.PostCount,
    u.BadgeCount,
    u.UpVotes,
    u.DownVotes,
    p.PostId,
    p.Title,
    p.Score,
    p.ViewCount,
    p.CommentCount,
    p.LastCommentDate
FROM UserStats u
JOIN PostStats p ON u.UserId = p.OwnerUserId
ORDER BY u.Reputation DESC, p.Score DESC
LIMIT 100; -- Benchmarks result for the top users by reputation and their posts

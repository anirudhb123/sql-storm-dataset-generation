-- Performance Benchmarking Query for StackOverflow Schema

WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(v.CreationDate IS NOT NULL) AS VoteCount,
        SUM(c.Id IS NOT NULL) AS CommentCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY u.Id, u.Reputation
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        p.Tags,
        pt.Name AS PostTypeName,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id, pt.Name
),
VoteStats AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN vt.Name = 'Close' THEN 1 ELSE 0 END) AS CloseVotes
    FROM Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY v.PostId
)

SELECT 
    us.UserId,
    us.Reputation,
    us.PostCount,
    us.BadgeCount,
    us.VoteCount AS TotalVotes,
    us.CommentCount AS TotalComments,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount AS PostCommentCount,
    ps.FavoriteCount,
    ps.Tags,
    ps.PostTypeName,
    vs.UpVotes,
    vs.DownVotes,
    vs.CloseVotes
FROM UserStats us
JOIN Posts p ON us.UserId = p.OwnerUserId
JOIN PostStats ps ON p.Id = ps.PostId
LEFT JOIN VoteStats vs ON ps.PostId = vs.PostId
ORDER BY us.Reputation DESC, ps.ViewCount DESC;

-- Performance benchmarking query for StackOverflow schema
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.UpVotes > 0 THEN 1 ELSE 0 END) AS UpvotedPosts,
        SUM(CASE WHEN p.DownVotes > 0 THEN 1 ELSE 0 END) AS DownvotedPosts,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        p.ClosedDate,
        COUNT(c.Id) AS CommentCount,
        AVG(v.BountyAmount) AS AvgBountyAmount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.AnswerCount, p.CommentCount, p.FavoriteCount, p.ClosedDate
)
SELECT 
    us.UserId,
    us.Reputation,
    us.PostCount,
    us.QuestionCount,
    us.AnswerCount,
    us.UpvotedPosts,
    us.DownvotedPosts,
    us.BadgeCount,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.AnswerCount AS PostAnswerCount,
    ps.CommentCount AS PostCommentCount,
    ps.FavoriteCount,
    ps.ClosedDate,
    ps.AvgBountyAmount
FROM UserStats us
JOIN PostStats ps ON us.UserId = ps.OwnerUserId
ORDER BY us.Reputation DESC, ps.ViewCount DESC
LIMIT 100;

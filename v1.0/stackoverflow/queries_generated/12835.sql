-- Performance Benchmarking SQL Query
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.VoteTypeId = 2) AS TotalUpvotes,
        SUM(v.VoteTypeId = 3) AS TotalDownvotes,
        SUM(b.Id IS NOT NULL) AS TotalBadges,
        MAX(p.CreationDate) AS LastPostDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        MAX(ph.CreationDate) AS LastEditDate
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id, p.Title, p.ViewCount, p.Score, p.AnswerCount, p.CommentCount, u.DisplayName
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalPosts,
    us.TotalComments,
    us.TotalUpvotes,
    us.TotalDownvotes,
    us.TotalBadges,
    us.LastPostDate,
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.Score,
    ps.AnswerCount,
    ps.CommentCount,
    ps.OwnerDisplayName,
    ps.LastEditDate
FROM UserStats us
JOIN PostStats ps ON us.UserId = ps.OwnerUserId
ORDER BY us.TotalPosts DESC, ps.ViewCount DESC;

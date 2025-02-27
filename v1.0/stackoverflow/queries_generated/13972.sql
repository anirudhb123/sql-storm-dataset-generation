-- Performance benchmarking query for analyzing user activity and post interactions
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT a.Id) AS TotalAcceptedAnswers,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS TotalVotes,
        SUM(coalesce(p.ViewCount, 0)) AS TotalViews
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Posts a ON a.AcceptedAnswerId = p.Id
    LEFT JOIN Votes v ON v.UserId = u.Id AND v.PostId = p.Id
    GROUP BY u.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.TotalAcceptedAnswers,
    us.TotalVotes,
    us.TotalViews,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.VoteCount
FROM UserStats us
JOIN PostStats ps ON ps.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = us.UserId)
ORDER BY us.Reputation DESC, ps.ViewCount DESC;

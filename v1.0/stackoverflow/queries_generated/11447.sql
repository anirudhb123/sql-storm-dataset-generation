-- Performance benchmarking query to retrieve user statistics and post insights
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.UpVotes > p.DownVotes THEN 1 ELSE 0 END) AS TotalUpvotedPosts,
        SUM(CASE WHEN p.FavoriteCount > 0 THEN 1 ELSE 0 END) AS TotalFavoritedPosts
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.CommentCount,
        p.AcceptedAnswerId,
        COUNT(c.Id) AS TotalComments,
        SUM(v.VoteTypeId = 2) AS TotalUpvotes,
        SUM(v.VoteTypeId = 3) AS TotalDownvotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.TotalQuestions,
    us.TotalAnswers,
    us.TotalUpvotedPosts,
    us.TotalFavoritedPosts,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.TotalComments,
    ps.TotalUpvotes,
    ps.TotalDownvotes
FROM UserStats us
JOIN PostStats ps ON us.UserId = ps.OwnerUserId
ORDER BY us.Reputation DESC, ps.Score DESC
LIMIT 100;  -- Limit results for performance benchmarking

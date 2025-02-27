WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        SUM(v.BountyAmount) AS TotalBounties,
        SUM(v.VoteTypeId = 2) AS TotalUpvotes,
        SUM(v.VoteTypeId = 3) AS TotalDownvotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
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
        u.DisplayName AS OwnerName
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalPosts,
    us.TotalBadges,
    us.TotalBounties,
    us.TotalUpvotes,
    us.TotalDownvotes,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.FavoriteCount,
    ps.OwnerName
FROM UserStats us
LEFT JOIN PostStats ps ON us.UserId = ps.OwnerName
ORDER BY us.TotalPosts DESC, us.TotalUpvotes DESC
LIMIT 100;

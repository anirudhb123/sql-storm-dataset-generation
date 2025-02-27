WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
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
        u.DisplayName AS OwnerName,
        (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = p.Id) AS TotalEditHistory,
        (SELECT STRING_AGG(pt.Name, ', ') FROM PostTypes pt WHERE pt.Id = p.PostTypeId) AS PostTypeName
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.TotalQuestions,
    us.TotalAnswers,
    us.TotalBounty,
    us.TotalCommentScore,
    us.TotalBadges,
    ps.Title AS PostTitle,
    ps.CreationDate AS PostCreationDate,
    ps.Score AS PostScore,
    ps.ViewCount AS PostViewCount,
    ps.AnswerCount AS PostAnswerCount,
    ps.CommentCount AS PostCommentCount,
    ps.FavoriteCount AS PostFavoriteCount,
    ps.TotalEditHistory AS PostTotalEditHistory,
    ps.PostTypeName AS PostType
FROM UserStats us
JOIN PostStats ps ON us.UserId = ps.OwnerName
ORDER BY us.Reputation DESC, ps.CreationDate DESC
LIMIT 100;

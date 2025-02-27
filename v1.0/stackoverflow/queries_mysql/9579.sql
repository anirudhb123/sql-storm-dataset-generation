
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
        COALESCE(SUM(b.Class), 0) AS TotalBadgePoints
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
), 
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        @row_number := IF(@prev_owner_user_id = p.OwnerUserId, @row_number + 1, 1) AS rn,
        @prev_owner_user_id := p.OwnerUserId
    FROM Posts p, (SELECT @row_number := 0, @prev_owner_user_id := NULL) AS vars
    WHERE p.CreationDate >= NOW() - INTERVAL 1 YEAR
    ORDER BY p.OwnerUserId, p.CreationDate DESC
), 
RankedUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.TotalPosts,
        us.TotalQuestions,
        us.TotalAnswers,
        us.TotalCommentScore,
        us.TotalBadgePoints,
        @user_rank := @user_rank + 1 AS UserRank
    FROM UserStats us, (SELECT @user_rank := 0) AS vars
    ORDER BY us.Reputation DESC, us.TotalPosts DESC
)

SELECT 
    ru.UserRank,
    ru.DisplayName,
    ru.Reputation,
    ru.TotalPosts,
    ru.TotalQuestions,
    ru.TotalAnswers,
    ru.TotalCommentScore,
    ru.TotalBadgePoints,
    ap.Title AS RecentlyActivePost,
    ap.CreationDate AS PostCreationDate,
    ap.Score AS PostScore,
    ap.ViewCount AS PostViewCount
FROM RankedUsers ru
LEFT JOIN ActivePosts ap ON ru.UserId = ap.OwnerUserId AND ap.rn = 1
WHERE ru.UserRank <= 100
ORDER BY ru.UserRank;

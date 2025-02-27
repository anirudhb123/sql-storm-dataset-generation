
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        @row_num := IF(@prev_user_id = u.Id, @row_num + 1, 1) AS ActivityRank,
        @prev_user_id := u.Id
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8
    CROSS JOIN (SELECT @row_num := 0, @prev_user_id := NULL) AS vars
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        DENSE_RANK() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL 30 DAY
),
ClosingReasons AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(cr.Name ORDER BY cr.Name SEPARATOR ', ') AS ClosingReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON ph.Comment = cr.Id
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId
)
SELECT 
    ua.DisplayName,
    ua.Reputation,
    ua.TotalPosts,
    ua.QuestionsCount,
    ua.AnswersCount,
    ua.TotalBounty,
    pp.Title AS PopularPostTitle,
    pp.Score AS PopularPostScore,
    pp.ViewCount AS PopularPostViews,
    cr.ClosingReasons
FROM UserActivity ua
LEFT JOIN PopularPosts pp ON ua.UserId = pp.Id
LEFT JOIN ClosingReasons cr ON pp.Id = cr.PostId
WHERE ua.ActivityRank <= 10
ORDER BY ua.Reputation DESC, pp.Score DESC;

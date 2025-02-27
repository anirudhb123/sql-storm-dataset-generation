
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        MAX(p.CreationDate) AS LastPostDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        @row_number := IF(@prev_user_id = p.OwnerUserId, @row_number + 1, 1) AS PostRank,
        @prev_user_id := p.OwnerUserId
    FROM Posts p,
    (SELECT @row_number := 0, @prev_user_id := NULL) AS init
    ORDER BY p.OwnerUserId, p.CreationDate DESC
)
SELECT 
    ua.DisplayName,
    ua.Reputation,
    ua.PostCount,
    ua.PositivePosts,
    ua.NegativePosts,
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.CreationDate
FROM UserActivity ua
LEFT JOIN PostStats ps ON ua.UserId = ps.PostId AND ps.PostRank = 1
WHERE ua.Reputation > 1000
  AND (ua.PostCount > 5 OR ps.AnswerCount > 2 OR ps.CommentCount > 10)
  AND ps.CreationDate IS NOT NULL
ORDER BY ua.Reputation DESC, ps.ViewCount DESC
LIMIT 10;

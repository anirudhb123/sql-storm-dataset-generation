
WITH RecursiveUserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        @row_num := IF(@prev_user_id = u.Id, @row_num + 1, 1) AS ActivityRank,
        @prev_user_id := u.Id
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    CROSS JOIN (SELECT @row_num := 0, @prev_user_id := NULL) AS vars
    GROUP BY u.Id, u.DisplayName, u.Reputation
    HAVING COUNT(p.Id) > 0
),

RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        p.Title,
        p.PostTypeId,
        ph.Comment,
        @comment_row_num := IF(@prev_post_id = ph.PostId, @comment_row_num + 1, 1) AS CommentRank,
        @prev_post_id := ph.PostId
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    CROSS JOIN (SELECT @comment_row_num := 0, @prev_post_id := NULL) AS vars
    WHERE ph.CreationDate > NOW() - INTERVAL 30 DAY
)

SELECT 
    ua.DisplayName,
    ua.Reputation,
    ua.PostCount,
    ua.QuestionCount,
    ua.AnswerCount,
    rp.Title,
    rp.Comment,
    rp.CreationDate AS LastCommentDate,
    CASE 
        WHEN rp.Comment IS NOT NULL THEN 'Engaged'
        ELSE 'Inactive'
    END AS EngagementStatus
FROM RecursiveUserActivity ua
LEFT JOIN RecentPostHistory rp ON ua.UserId = rp.UserId
WHERE ua.ActivityRank = 1  
ORDER BY ua.Reputation DESC, LastCommentDate DESC
LIMIT 50;

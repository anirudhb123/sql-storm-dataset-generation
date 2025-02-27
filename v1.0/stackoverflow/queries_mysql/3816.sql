
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        @row_number := @row_number + 1 AS Rank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    CROSS JOIN (SELECT @row_number := 0) r
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        AnswerCount,
        CommentCount,
        UpvoteCount,
        DownvoteCount,
        Rank
    FROM UserActivity
    WHERE Rank <= 10
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        COALESCE(ph.UserDisplayName, 'Not Edited') AS LastEditedBy,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(DISTINCT c.Id) AS TotalComments,
        @post_row_number := IF(@current_user_id = p.OwnerUserId, @post_row_number + 1, 1) AS PostRank,
        @current_user_id := p.OwnerUserId
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 6)
    LEFT JOIN Comments c ON p.Id = c.PostId
    CROSS JOIN (SELECT @current_user_id := NULL, @post_row_number := 0) r
    GROUP BY p.Id, p.Title, p.Score, ph.UserDisplayName
)
SELECT 
    tu.DisplayName,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.CommentCount,
    tu.UpvoteCount,
    tu.DownvoteCount,
    ps.Title,
    ps.Score,
    ps.LastEditedBy,
    ps.LastEditDate,
    ps.TotalComments
FROM TopUsers tu
JOIN PostStats ps ON tu.UserId = ps.PostId
WHERE ps.PostRank <= 5
ORDER BY tu.Rank, ps.Score DESC;

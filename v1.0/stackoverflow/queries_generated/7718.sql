WITH UserActivity AS (
    SELECT u.Id AS UserId, u.DisplayName, SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
           SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount,
           SUM(v.VoteTypeId = 2) AS UpvoteCount, SUM(v.VoteTypeId = 3) AS DownvoteCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id
),
TopUsers AS (
    SELECT UserId, DisplayName, QuestionCount, AnswerCount, CommentCount,
           UpvoteCount - DownvoteCount AS NetVoteCount,
           RANK() OVER (ORDER BY (QuestionCount + AnswerCount) DESC, NetVoteCount DESC) AS Rank
    FROM UserActivity
)
SELECT tu.DisplayName, tu.QuestionCount, tu.AnswerCount, tu.CommentCount, tu.NetVoteCount
FROM TopUsers tu
WHERE tu.Rank <= 10
ORDER BY tu.Rank;

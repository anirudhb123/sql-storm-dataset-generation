
WITH UserMetrics AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalUpVotes,
        TotalDownVotes,
        BadgeCount,
        @rank := @rank + 1 AS Rank
    FROM UserMetrics, (SELECT @rank := 0) r
    ORDER BY PostCount DESC, TotalUpVotes DESC
)
SELECT
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalUpVotes,
    TotalDownVotes,
    BadgeCount,
    Rank
FROM TopUsers
WHERE Rank <= 10
ORDER BY Rank;

WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        AVG(DATEDIFF(MINUTE, p.CreationDate, GETDATE())) AS AvgPostAge
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2
    LEFT JOIN Votes v ON v.UserId = u.Id
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        QuestionCount, 
        AnswerCount, 
        UpVotes, 
        DownVotes, 
        AvgPostAge,
        RANK() OVER (ORDER BY QuestionCount DESC, AnswerCount DESC) AS Rank
    FROM UserActivity
)
SELECT 
    tu.DisplayName,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.UpVotes,
    tu.DownVotes,
    tu.AvgPostAge,
    RANK() OVER (ORDER BY AVG(tu.UpVotes * 1.0 / NULLIF(tu.QuestionCount + tu.AnswerCount, 0)) DESC) AS EngagementRank
FROM TopUsers tu
WHERE tu.Rank <= 10
ORDER BY tu.UpVotes DESC, tu.AnswerCount DESC;


WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COALESCE(SUM(vs.VoteCount), 0) AS TotalVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) vs ON p.Id = vs.PostId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalVotes,
        @rank := IF(@prevTotalVotes = TotalVotes, @rank, @rank + 1) AS Rank,
        @prevTotalVotes := TotalVotes
    FROM UserPostStats, (SELECT @rank := 0, @prevTotalVotes := NULL) r
    ORDER BY TotalVotes DESC
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalVotes
FROM TopUsers
WHERE Rank <= 10
ORDER BY TotalVotes DESC;

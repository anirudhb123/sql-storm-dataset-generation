
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS ClosedQuestionCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        QuestionCount, 
        AnswerCount, 
        ClosedQuestionCount,
        @rank := @rank + 1 AS Rank
    FROM 
        UserStats, (SELECT @rank := 0) r
    WHERE 
        QuestionCount > 0
    ORDER BY 
        Reputation DESC
),
RecentVotes AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY 
        v.UserId
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.ClosedQuestionCount,
    rv.TotalVotes AS RecentTotalVotes,
    rv.UpVotes AS RecentUpVotes,
    rv.DownVotes AS RecentDownVotes
FROM 
    TopUsers tu
LEFT JOIN 
    RecentVotes rv ON tu.UserId = rv.UserId
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.Reputation DESC;

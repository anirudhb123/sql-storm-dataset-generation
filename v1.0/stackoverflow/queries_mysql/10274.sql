
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId IN (3, 4, 5) THEN 1 ELSE 0 END) AS WikiCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        WikiCount,
        UpVoteCount,
        DownVoteCount,
        @rank := IF(@prev_rank = Reputation, @rank, @count) AS ReputationRank,
        @prev_rank := Reputation,
        @count := @count + 1
    FROM UserStatistics, (SELECT @rank := 0, @count := 0, @prev_rank := NULL) AS vars
    ORDER BY Reputation DESC
)
SELECT 
    UserId,
    Reputation,
    PostCount,
    QuestionCount,
    AnswerCount,
    WikiCount,
    UpVoteCount,
    DownVoteCount,
    ReputationRank
FROM TopUsers
WHERE ReputationRank <= 10
ORDER BY ReputationRank;

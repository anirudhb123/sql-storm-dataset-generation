
WITH UserStatistics AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        UpVoteCount,
        DownVoteCount,
        QuestionCount,
        AnswerCount,
        @rownum := @rownum + 1 AS Rank
    FROM UserStatistics, (SELECT @rownum := 0) r
    ORDER BY Reputation DESC
)
SELECT *
FROM TopUsers
WHERE Rank <= 10;

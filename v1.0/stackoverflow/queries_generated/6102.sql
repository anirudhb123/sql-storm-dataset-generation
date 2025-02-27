WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(V.VoteTypeId = 2, 0)) AS UpVotes,
        SUM(COALESCE(V.VoteTypeId = 3, 0)) AS DownVotes,
        SUM(COALESCE(B.Id, 0)) AS BadgeCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        UpVotes,
        DownVotes,
        BadgeCount,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserStats
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostCount,
    QuestionCount,
    AnswerCount,
    UpVotes,
    DownVotes,
    BadgeCount,
    ReputationRank
FROM TopUsers
WHERE ReputationRank <= 10
ORDER BY Reputation DESC;

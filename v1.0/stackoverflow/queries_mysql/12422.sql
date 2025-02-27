
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBountyAmount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8  
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.Reputation, U.CreationDate
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalBountyAmount,
        BadgeCount,
        @row_num := @row_num + 1 AS ReputationRank
    FROM UserStats, (SELECT @row_num := 0) AS rn
    ORDER BY Reputation DESC
)
SELECT 
    UserId,
    Reputation,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalBountyAmount,
    BadgeCount,
    ReputationRank
FROM TopUsers
WHERE ReputationRank <= 10;

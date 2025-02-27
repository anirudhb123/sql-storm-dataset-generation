WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(V.BountyAmount) AS TotalBounty
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
), UserRanked AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        QuestionCount,
        AnswerCount,
        CommentCount,
        BadgeCount,
        TotalBounty,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        RANK() OVER (ORDER BY TotalBounty DESC) AS BountyRank
    FROM UserStats
), TopUsers AS (
    SELECT 
        * 
    FROM UserRanked 
    WHERE 
        ReputationRank <= 10 OR 
        BountyRank <= 10
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    QuestionCount,
    AnswerCount,
    CommentCount,
    BadgeCount,
    TotalBounty,
    ReputationRank,
    BountyRank
FROM TopUsers
ORDER BY Reputation DESC, Bounty DESC;

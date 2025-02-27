WITH RECURSIVE UserReputationCTE AS (
    SELECT U.Id, U.DisplayName, 
           U.Reputation AS TotalReputation, 
           U.CreationDate,
           1 AS Level
    FROM Users U
    WHERE U.Reputation IS NOT NULL AND U.Reputation > 0

    UNION ALL

    SELECT U.Id, U.DisplayName, 
           U.Reputation + CTE.TotalReputation,
           U.CreationDate,
           CTE.Level + 1
    FROM Users U
    JOIN UserReputationCTE CTE ON U.Id = CTE.Id
    WHERE U.Reputation + CTE.TotalReputation < 10000
),

TopUsers AS (
    SELECT Id, DisplayName, TotalReputation,
           DENSE_RANK() OVER (ORDER BY TotalReputation DESC) AS Rank
    FROM UserReputationCTE
),

RecentPosts AS (
    SELECT P.Id, P.Title, P.CreationDate, P.OwnerUserId, P.Score,
           COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
           COUNT(DISTINCT V.Id) AS VoteCount
    FROM Posts P
    LEFT JOIN Comments C ON C.PostId = P.Id
    LEFT JOIN Votes V ON V.PostId = P.Id
    WHERE P.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY P.Id
),

UserPostStats AS (
    SELECT U.Id AS UserId, 
           U.DisplayName AS UserName,
           COALESCE(SUM(P.Score), 0) AS UserPostScore,
           COUNT(DISTINCT P.Id) AS PostCount
    FROM Users U
    LEFT JOIN Posts P ON P.OwnerUserId = U.Id
    GROUP BY U.Id, U.DisplayName
),

CombinedStats AS (
    SELECT U.Id AS UserId,
           U.DisplayName,
           U.Reputation,
           COALESCE(RP.UserPostScore, 0) AS PostScore,
           COALESCE(RP.PostCount, 0) AS TotalPosts,
           COALESCE(RC.CommentCount, 0) AS TotalComments
    FROM Users U
    LEFT JOIN UserPostStats RP ON U.Id = RP.UserId
    LEFT JOIN (
        SELECT P.OwnerUserId, 
               COUNT(C.Id) AS CommentCount
        FROM Posts P
        LEFT JOIN Comments C ON P.Id = C.PostId
        GROUP BY P.OwnerUserId
    ) RC ON U.Id = RC.OwnerUserId
)

SELECT C.UserId, 
       C.UserName, 
       C.Reputation, 
       C.PostScore, 
       C.TotalPosts, 
       C.TotalComments,
       TP.Rank,
       ROW_NUMBER() OVER (PARTITION BY C.UserId ORDER BY C.PostScore DESC) AS UserRank
FROM CombinedStats C
LEFT JOIN TopUsers TP ON C.UserId = TP.Id
WHERE C.Reputation IS NOT NULL
ORDER BY C.TotalPosts DESC, C.PostScore DESC;

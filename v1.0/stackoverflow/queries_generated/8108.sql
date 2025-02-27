WITH UserReputation AS (
    SELECT U.Id AS UserId, U.Reputation, COUNT(DISTINCT P.Id) AS PostCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.Reputation
),
TopUsers AS (
    SELECT UserId, Reputation, PostCount
    FROM UserReputation
    WHERE PostCount > 0
    ORDER BY Reputation DESC
    LIMIT 10
),
ActivePosts AS (
    SELECT P.Id AS PostId, P.Title, P.CreationDate, P.Score, COUNT(C.Id) AS CommentCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score
),
UserActivity AS (
    SELECT U.Id AS UserId, U.DisplayName, COUNT(DISTINCT P.Id) AS TotalPosts, 
           SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
           SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
           SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalComments
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY U.Id, U.DisplayName
)
SELECT U.DisplayName, U.Reputation, U.TotalPosts, U.Questions, U.Answers, 
       A.PostId, A.Title, A.CreationDate, A.Score, A.CommentCount
FROM UserActivity U
JOIN ActivePosts A ON U.TotalPosts > 0
JOIN TopUsers T ON U.UserId = T.UserId
ORDER BY U.Reputation DESC, A.Score DESC
LIMIT 20;

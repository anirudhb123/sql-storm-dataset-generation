WITH UserReputation AS (
    SELECT Id, Reputation, CreationDate,
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
RecentPosts AS (
    SELECT P.Id, P.Title, P.ViewCount, P.Score, 
           COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
           COUNT(CASE WHEN V.Id IS NOT NULL AND V.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
           COUNT(CASE WHEN V.Id IS NOT NULL AND V.VoteTypeId = 3 THEN 1 END) AS DownVoteCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate > CURRENT_DATE - INTERVAL '30 days'
    GROUP BY P.Id
),
TopUsers AS (
    SELECT U.Id AS UserId, U.DisplayName, U.Reputation, 
           COALESCE(SUM(CASE WHEN U.Id = P.OwnerUserId THEN 1 ELSE 0 END), 0) AS PostCount,
           COALESCE(SUM(CASE WHEN U.Id = C.UserId THEN 1 ELSE 0 END), 0) AS CommentCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    GROUP BY U.Id
    HAVING COUNT(DISTINCT P.Id) > 0
)
SELECT U.DisplayName, U.Reputation, U.PostCount, U.CommentCount, R.ViewCount, R.Score
FROM TopUsers U
JOIN RecentPosts R ON U.PostCount > 0
WHERE U.ReputationRank BETWEEN 1 AND 10
ORDER BY U.Reputation DESC, R.ViewCount DESC
LIMIT 10;

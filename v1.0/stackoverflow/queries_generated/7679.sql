WITH UserScores AS (
    SELECT U.Id AS UserId,
           U.DisplayName,
           SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
           SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
           COUNT(DISTINCT P.Id) AS PostCount,
           SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE U.Reputation > 1000
    GROUP BY U.Id
), TopUsers AS (
    SELECT UserId, DisplayName, Upvotes, Downvotes, PostCount, TotalScore,
           RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM UserScores
    WHERE PostCount > 5
)
SELECT U.DisplayName, 
       U.TotalScore, 
       U.Upvotes, 
       U.Downvotes, 
       Rank.ScoreRank, 
       COUNT(DISTINCT C.Id) AS CommentCount
FROM TopUsers U
JOIN Comments C ON U.UserId = C.UserId
JOIN PostHistory PH ON C.PostId = PH.PostId
WHERE PH.CreationDate BETWEEN NOW() - INTERVAL '30 days' AND NOW()
GROUP BY U.DisplayName, U.TotalScore, U.Upvotes, U.Downvotes, Rank.ScoreRank
ORDER BY Rank.ScoreRank
LIMIT 10;

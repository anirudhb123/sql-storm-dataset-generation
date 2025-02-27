
WITH UserReputation AS (
    SELECT Id, Reputation, CreationDate, LastAccessDate, 
           @row_number := @row_number + 1 AS Rank,
           @dense_rank := IF(@prev_reputation = Reputation, @dense_rank, @dense_rank + 1) AS DenseRank,
           @prev_reputation := Reputation
    FROM Users, (SELECT @row_number := 0, @dense_rank := 0, @prev_reputation := NULL) AS vars
    WHERE Reputation > 1000
    ORDER BY Reputation DESC
),
ActivePosts AS (
    SELECT P.Id AS PostId, P.OwnerUserId, P.ViewCount, P.CreationDate, P.LastActivityDate,
           COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
           SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY P.Id, P.OwnerUserId, P.ViewCount, P.CreationDate, P.LastActivityDate
),
TopUsers AS (
    SELECT U.Id, U.DisplayName, U.Reputation, UR.Rank
    FROM Users U
    JOIN UserReputation UR ON U.Id = UR.Id
    WHERE UR.Rank <= 10
),
PostStatistics AS (
    SELECT AP.OwnerUserId, COUNT(AP.PostId) AS TotalPosts, 
           SUM(AP.ViewCount) AS TotalViews, 
           SUM(AP.UpVotes) AS TotalUpVotes, 
           SUM(AP.DownVotes) AS TotalDownVotes
    FROM ActivePosts AP
    GROUP BY AP.OwnerUserId
)
SELECT TU.DisplayName, TU.Reputation, PS.TotalPosts, PS.TotalViews, PS.TotalUpVotes, PS.TotalDownVotes
FROM TopUsers TU
LEFT JOIN PostStatistics PS ON TU.Id = PS.OwnerUserId
ORDER BY TU.Reputation DESC, PS.TotalViews DESC;

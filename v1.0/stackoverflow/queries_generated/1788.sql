WITH UserReputation AS (
    SELECT Id, DisplayName, Reputation, 
           RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
PostDetails AS (
    SELECT P.Id AS PostId, P.OwnerUserId, P.Title, P.CreationDate, P.Score, 
           (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS TotalComments,
           (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpVotes,
           (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS DownVotes
    FROM Posts P
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year'
),
PostHistoryAggregate AS (
    SELECT PH.PostId, 
           MIN(CASE WHEN PH.PostHistoryTypeId = 10 THEN PH.CreationDate END) AS FirstClosedDate,
           COUNT(*) FILTER (WHERE PH.PostHistoryTypeId IN (10, 11)) AS CloseReopenCount
    FROM PostHistory PH
    GROUP BY PH.PostId
)
SELECT UR.DisplayName, UR.Reputation, UR.ReputationRank,
       PD.Title, PD.CreationDate, PD.Score, PD.TotalComments, PD.UpVotes, PD.DownVotes,
       COALESCE(PHA.FirstClosedDate, 'Not Closed') AS FirstClosedDate,
       COALESCE(PHA.CloseReopenCount, 0) AS CloseReopenCount
FROM UserReputation UR
JOIN PostDetails PD ON UR.Id = PD.OwnerUserId
LEFT JOIN PostHistoryAggregate PHA ON PD.PostId = PHA.PostId
WHERE UR.Reputation > 1000
ORDER BY UR.Reputation DESC, PD.Score DESC
LIMIT 50
OFFSET 0;

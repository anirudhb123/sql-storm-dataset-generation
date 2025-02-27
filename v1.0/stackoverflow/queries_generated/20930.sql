WITH UserReputation AS (
    SELECT U.Id AS UserId, 
           U.Reputation,
           CASE 
               WHEN U.Reputation < 100 THEN 'Newbie'
               WHEN U.Reputation BETWEEN 100 AND 999 THEN 'Intermediate'
               WHEN U.Reputation >= 1000 THEN 'Experienced'
               ELSE 'Unknown'
           END AS ReputationLevel
    FROM Users U
), 
PostDetails AS (
    SELECT P.Id AS PostId, 
           P.Title, 
           P.ViewCount, 
           P.CreationDate, 
           P.Score,
           PT.Name AS PostTypeName,
           COALESCE(PA.AcceptedAnswerId, -1) AS AcceptedAnswer 
    FROM Posts P
    JOIN PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN Posts PA ON P.AcceptedAnswerId = PA.Id
), 
VoteSummary AS (
    SELECT PostId, 
           SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
           COUNT(*) AS TotalVotes 
    FROM Votes V
    GROUP BY PostId
), 
PostHistorySummary AS (
    SELECT PH.PostId,
           MAX(CASE WHEN PH.PostHistoryTypeId = 10 THEN PH.CreationDate END) AS ClosuredDate,
           COUNT(CASE WHEN PH.PostHistoryTypeId IN (10, 11, 12) THEN 1 END) AS ModificationCount
    FROM PostHistory PH
    GROUP BY PH.PostId
), 
CombinedData AS (
    SELECT U.UserId, 
           U.ReputationLevel, 
           PD.PostId, 
           PD.Title, 
           PD.ViewCount, 
           PD.CreationDate,
           PD.Score,
           PS.UpVotes,
           PS.DownVotes,
           PHS.ClosuredDate,
           PHS.ModificationCount
    FROM UserReputation U
    JOIN PostDetails PD ON U.UserId = PD.AcceptedAnswer 
    LEFT JOIN VoteSummary PS ON PD.PostId = PS.PostId
    LEFT JOIN PostHistorySummary PHS ON PD.PostId = PHS.PostId
    WHERE U.ReputationLevel IS NOT NULL
)

SELECT CD.UserId, 
       CD.Title, 
       CD.ViewCount, 
       CD.Score, 
       CD.UpVotes,
       CD.DownVotes,
       COALESCE(CD.ClosuredDate, 'Not Closed') AS ClosuredStatus,
       'Reputation Level: ' || CD.ReputationLevel || 
       ' | Modifications: ' || CD.ModificationCount AS Details
FROM CombinedData CD
WHERE CD.Score > 0
ORDER BY CD.Score DESC, 
         CD.ViewCount DESC
LIMIT 10;

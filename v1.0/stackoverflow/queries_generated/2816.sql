WITH UserReputation AS (
    SELECT U.Id AS UserId, 
           U.DisplayName, 
           U.Reputation, 
           U.CreationDate, 
           U.LastAccessDate, 
           RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users AS U
    WHERE U.Reputation > 1000
), 
TopPosts AS (
    SELECT P.Id AS PostId, 
           P.Title, 
           P.CreationDate, 
           P.Score, 
           P.OwnerUserId, 
           ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM Posts AS P
    WHERE P.ViewCount > 100
), 
PostStats AS (
    SELECT TP.PostId, 
           TP.Title, 
           TP.CreationDate,
           TP.Score, 
           COALESCE(COUNT(C.ID), 0) AS CommentCount,
           (SELECT COUNT(V.Id) 
            FROM Votes AS V 
            WHERE V.PostId = TP.PostId AND V.VoteTypeId = 2) AS UpvoteCount,
           (SELECT COUNT(V.Id) 
            FROM Votes AS V 
            WHERE V.PostId = TP.PostId AND V.VoteTypeId = 3) AS DownvoteCount
    FROM TopPosts AS TP
    LEFT JOIN Comments AS C ON TP.PostId = C.PostId
    GROUP BY TP.PostId, TP.Title, TP.CreationDate, TP.Score
), 
PostHistoryStats AS (
    SELECT PH.PostId, 
           COUNT(PH.Id) AS EditCount,
           MAX(PH.CreationDate) AS LastEditDate
    FROM PostHistory AS PH
    WHERE PH.PostHistoryTypeId IN (4, 5, 6)
    GROUP BY PH.PostId
)
SELECT UR.DisplayName, 
       UR.Reputation, 
       UR.ReputationRank, 
       PS.PostId, 
       PS.Title AS PostTitle, 
       PS.CreationDate AS PostCreationDate, 
       PS.Score AS PostScore, 
       PS.CommentCount, 
       PH.EditCount AS EditHistoryCount,
       PH.LastEditDate 
FROM UserReputation AS UR
JOIN PostStats AS PS ON UR.UserId = PS.OwnerUserId
LEFT JOIN PostHistoryStats AS PH ON PS.PostId = PH.PostId
WHERE UR.ReputationRank <= 10 
AND (PS.Score - (SELECT COALESCE(SUM(VB.BountyAmount), 0) FROM Votes AS VB WHERE VB.PostId = PS.PostId AND VB.VoteTypeId = 8)) > 0
HAVING PS.Score > 5
ORDER BY UR.Reputation DESC, PS.Score DESC;

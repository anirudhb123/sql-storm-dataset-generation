WITH UserReputation AS (
    SELECT U.Id AS UserId,
           U.DisplayName,
           U.Reputation,
           COALESCE(AVG(V.Score), 0) AS AvgVoteScore,
           COUNT(DISTINCT B.Id) AS BadgeCount,
           COUNT(DISTINCT P.Id) AS PostCount
    FROM Users U
    LEFT JOIN Votes V ON V.UserId = U.Id
    LEFT JOIN Badges B ON B.UserId = U.Id
    LEFT JOIN Posts P ON P.OwnerUserId = U.Id
    GROUP BY U.Id
),
PostStats AS (
    SELECT P.Id AS PostId,
           P.Title,
           P.CreationDate,
           COALESCE(SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
           COUNT(DISTINCT PH.Id) FILTER (WHERE PH.PostHistoryTypeId IN (10, 11)) AS CloseChanges,
           MAX(P.History) AS LastHistoryId
    FROM Posts P
    LEFT JOIN Comments C ON C.PostId = P.Id
    LEFT JOIN PostHistory PH ON PH.PostId = P.Id
    GROUP BY P.Id, P.Title, P.CreationDate
),
TagPopularity AS (
    SELECT UNNEST(STRING_TO_ARRAY(T.Tags, ',')) AS Tag, COUNT(P.Id) AS PostCount
    FROM Posts P
    JOIN Tags T ON T.Id = P.Id
    GROUP BY Tag
),
PollResults AS (
    SELECT V.PostId, 
           SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE -1 END) AS VoteBalance
    FROM Votes V
    GROUP BY V.PostId
),
FinalResults AS (
    SELECT UR.UserId, 
           UR.DisplayName, 
           UR.Reputation,
           PS.PostCount,
           PS.CommentCount,
           PP.PostId,
           PP.Title,
           PP.CreationDate,
           PP.CloseChanges,
           PP.LastHistoryId,
           TP.Tag,
           PR.VoteBalance
    FROM UserReputation UR
    JOIN PostStats PS ON PS.CommentCount > 0 OR PS.CloseChanges > 0
    LEFT JOIN TagPopularity TP ON TP.PostCount > 0
    LEFT JOIN PollResults PR ON PR.PostId = PS.PostId
)

SELECT *
FROM FinalResults
WHERE (Reputation > 1000 OR BadgeCount > 5)
  AND (VoteBalance IS NULL OR VoteBalance > 0)
ORDER BY Reputation DESC, CommentCount DESC, CreationDate;

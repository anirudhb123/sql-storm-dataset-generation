
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        (U.UpVotes - U.DownVotes) AS NetVotes,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.Views, U.UpVotes, U.DownVotes
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        P.Score,
        P.AnswerCount,
        (SELECT COUNT(*) 
         FROM Votes V 
         WHERE V.PostId = P.Id AND V.VoteTypeId IN (2, 3)) AS TotalVotes,
        P.OwnerUserId,
        P.CreationDate,
        (SELECT P2.CreationDate 
         FROM Posts P2 
         WHERE P2.OwnerUserId = P.OwnerUserId AND P2.CreationDate > P.CreationDate 
         ORDER BY P2.CreationDate 
         LIMIT 1) AS NextPostDate
    FROM Posts P
    WHERE P.CreationDate >= DATE_SUB('2024-10-01 12:34:56', INTERVAL 1 YEAR)
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        COUNT(*) AS EditCount,
        GROUP_CONCAT(DISTINCT PH.UserDisplayName ORDER BY PH.UserDisplayName SEPARATOR ', ') AS Editors
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (4, 5)
    GROUP BY PH.PostId, PH.PostHistoryTypeId
),
CombinedStats AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.Score,
        PS.AnswerCount,
        PS.TotalVotes,
        US.DisplayName,
        US.Reputation,
        US.BadgeCount,
        PHD.EditCount,
        PHD.Editors,
        PS.CreationDate,
        PS.NextPostDate
    FROM PostDetails PS
    JOIN UserStats US ON PS.OwnerUserId = US.UserId
    LEFT JOIN PostHistoryDetails PHD ON PS.PostId = PHD.PostId
)
SELECT 
    CS.Title,
    CS.Score,
    CS.AnswerCount,
    COALESCE(CS.EditCount, 0) AS EditCount,
    CS.DisplayName,
    CS.Reputation,
    CASE 
        WHEN CS.Reputation > 1000 THEN 'High Reputation'
        WHEN CS.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory,
    CASE 
        WHEN CS.BadgeCount > 10 THEN 'Badge Collector'
        ELSE 'Novice'
    END AS BadgeCategory,
    CS.CreationDate,
    CS.NextPostDate
FROM CombinedStats CS
WHERE CS.TotalVotes > 5
  AND (CS.EditCount IS NULL OR CS.EditCount < 3)
ORDER BY CS.Score DESC
LIMIT 50;

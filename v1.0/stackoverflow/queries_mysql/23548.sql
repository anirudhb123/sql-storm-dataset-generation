
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBountyAmount,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.AnswerCount,
        P.ViewCount,
        P.CreationDate,
        P.ClosedDate,
        L.LinkTypeId,
        PH.PostHistoryTypeId,
        PH.Comment,
        GROUP_CONCAT(T.TagName ORDER BY T.TagName SEPARATOR ', ') AS Tags
    FROM Posts P
    LEFT JOIN PostLinks L ON P.Id = L.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN (
        SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '>', numbers.n), '>', -1) AS TagName
        FROM 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL 
         SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
        WHERE CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '>', '')) >= numbers.n - 1
    ) T ON TRUE
    WHERE P.ViewCount > 100 AND P.CreationDate < NOW() - INTERVAL 1 YEAR
    GROUP BY P.Id, P.Title, P.Score, P.AnswerCount, P.ViewCount, P.CreationDate, P.ClosedDate, L.LinkTypeId, PH.PostHistoryTypeId, PH.Comment
),
PostStatistics AS (
    SELECT
        PD.PostId,
        PD.Title,
        PD.Score,
        PD.AnswerCount,
        PD.ViewCount,
        PD.ClosedDate,
        U.DisplayName AS MostActiveUser,
        COUNT(CASE WHEN C.UserId IS NOT NULL THEN 1 END) AS CommentCount,
        DENSE_RANK() OVER (PARTITION BY PD.PostId ORDER BY PD.ViewCount DESC) AS ViewRank
    FROM PostDetails PD
    LEFT JOIN Comments C ON PD.PostId = C.PostId
    LEFT JOIN Users U ON C.UserId = U.Id
    GROUP BY PD.PostId, PD.Title, PD.Score, PD.AnswerCount, PD.ViewCount, PD.ClosedDate, U.DisplayName
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.Score,
    PS.AnswerCount,
    PS.ViewCount,
    PS.ClosedDate,
    PS.MostActiveUser,
    (SELECT COUNT(*) FROM PostHistory WHERE PostId = PS.PostId AND PostHistoryTypeId = 10) AS CloseVotes,
    (SELECT COUNT(*) FROM PostHistory WHERE PostId = PS.PostId AND PostHistoryTypeId = 13) AS UndeleteVotes,
    UR.Reputation,
    UR.TotalBountyAmount
FROM PostStatistics PS
JOIN UserReputation UR ON PS.MostActiveUser = UR.DisplayName
WHERE UR.Reputation > 100
ORDER BY PS.ViewCount DESC, PS.ClosedDate DESC
LIMIT 10;

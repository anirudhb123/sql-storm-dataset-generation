WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBountyAmount,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id
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
        STRING_AGG(T.TagName, ', ') AS Tags
    FROM Posts P
    LEFT JOIN PostLinks L ON P.Id = L.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN LATERAL (
        SELECT UNNEST(STRING_TO_ARRAY(P.Tags, '>')) AS TagName
    ) T ON TRUE
    WHERE P.ViewCount > 100 AND P.CreationDate < NOW() - INTERVAL '1 year'
    GROUP BY P.Id, L.LinkTypeId, PH.PostHistoryTypeId, PH.Comment
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

-- This query gathers performance metrics regarding posts in the Stack Overflow schema using various features:
-- CTEs for breaking the complex query down into manageable parts,
-- STRING_AGG for aggregating tag names,
-- LATERAL joins to unnest tags,
-- window functions for ranking users and posts,
-- compound predicates for filtering posts based on views and dates,
-- outer joins to ensure all relevant data points are included while gracefully handling NULLs.

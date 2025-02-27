WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViewCount,
        SUM(P.Score) AS TotalScore,
        DENSE_RANK() OVER (ORDER BY SUM(P.Score) DESC) AS RankByScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE U.Reputation > 1000
    GROUP BY U.Id
),
PostStatistics AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.CommentCount,
        P.CreationDate,
        COALESCE(PH.ClosedDate, 'No Close') AS PostClosureStatus,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostOrder
    FROM Posts P
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (10, 11) 
    WHERE P.CreationDate > NOW() - INTERVAL '1 year'
)
SELECT 
    UE.DisplayName,
    UE.CommentCount,
    UE.TotalViewCount,
    UE.TotalScore,
    PS.Title,
    PS.ViewCount,
    PS.Score,
    PS.AnswerCount,
    PS.CommentCount,
    PS.CreationDate,
    PS.PostClosureStatus
FROM UserEngagement UE
JOIN PostStatistics PS ON UE.UserId = PS.OwnerUserId
WHERE UE.RankByScore <= 10
ORDER BY UE.TotalScore DESC, PS.CreationDate DESC
LIMIT 50;

-- This query retrieves the top ranked users based on their engagement metrics, 
-- along with recent post statistics, applying various analytical functions, 
-- outer joins, and aggregations while filtering by specific criteria and 
-- handling possible NULL values effectively.

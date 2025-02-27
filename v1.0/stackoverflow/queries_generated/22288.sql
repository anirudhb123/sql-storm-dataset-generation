WITH UserReputation AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id
), PostAnalytics AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        CASE 
            WHEN P.Score >= 0 THEN 'Positive'
            WHEN P.Score < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS Sentiment,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT PH.Id) FILTER (WHERE PH.PostHistoryTypeId IN (10,11)) AS CloseReopenCount,
        SUM(CASE WHEN PH.PostHistoryTypeId = 12 THEN 1 ELSE 0 END) AS DeleteCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    GROUP BY P.Id
), DistinctTags AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY T.TagName
)
SELECT 
    UR.DisplayName,
    UR.Reputation,
    UR.TotalBounties,
    PA.Title,
    PA.CreationDate,
    PA.ViewCount,
    PA.Sentiment,
    PA.TotalComments,
    PA.CloseReopenCount,
    PA.DeleteCount,
    DT.TagName,
    DT.PostCount
FROM UserReputation UR
JOIN PostAnalytics PA ON PA.TotalComments > 0
LEFT JOIN DistinctTags DT ON DT.PostCount > 5
WHERE UR.Reputation > (SELECT AVG(Reputation) FROM Users) 
  AND PA.CloseReopenCount > 0
  AND PA.DeleteCount IS NULL
ORDER BY UR.Reputation DESC, PA.ViewCount DESC
LIMIT 100;

WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    WHERE U.CreationDate < NOW() - INTERVAL '1 year'
    GROUP BY U.Id, U.DisplayName, U.Reputation
), 
RankedUsers AS (
    SELECT 
        UA.*,
        ROW_NUMBER() OVER (ORDER BY UA.Reputation DESC) AS UserRank
    FROM UserActivity UA
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COALESCE(PH.Comment, 'No comments') AS LastComment,
        PH.CreationDate AS LastHistoryDate
    FROM Posts P
    LEFT JOIN PostHistory PH ON PH.PostId = P.Id AND PH.CreationDate = (
        SELECT MAX(PH2.CreationDate)
        FROM PostHistory PH2
        WHERE PH2.PostId = P.Id
    )
    WHERE P.CreationDate >= NOW() - INTERVAL '6 months'
    AND (P.Score > 0 OR P.ViewCount > 100)
)
SELECT 
    RU.UserRank,
    RU.DisplayName,
    RU.Reputation,
    PD.PostId,
    PD.Title,
    PD.CreationDate,
    PD.ViewCount,
    PD.LastComment,
    CASE 
        WHEN PD.LastHistoryDate IS NULL THEN 'No History'
        WHEN PD.LastHistoryDate < NOW() - INTERVAL '1 month' THEN 'Old Update'
        ELSE 'Recently Updated'
    END AS UpdateStatus,
    CASE 
        WHEN RU.Reputation IS NULL THEN 'Unknown Reputation'
        WHEN RU.Reputation < 0 THEN 'Negative Reputation'
        ELSE CAST(RU.Reputation / NULLIF((SELECT COUNT(*) FROM Posts P2), 0) * 100 AS INT) || '%' 
    END AS ReputationPercentage
FROM RankedUsers RU
LEFT JOIN PostDetails PD ON RU.UserId = PD.OwnerUserId
WHERE RU.UserRank <= 10 OR PD.ViewCount > 50
ORDER BY RU.UserRank, PD.ViewCount DESC
LIMIT 100;

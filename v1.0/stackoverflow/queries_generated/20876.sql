WITH UserReputationCTE AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        AVG(COALESCE(P.Score, 0)) AS AvgPostScore
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.Reputation
),
PostCloseReasons AS (
    SELECT 
        PH.PostId,
        PH.Comment AS CloseReason,
        COUNT(PH.Id) AS CloseCount
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (10, 11) -- Close and Reopen reasons
    GROUP BY PH.PostId, PH.Comment
),
RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM Posts P
    WHERE P.PostTypeId = 1 -- Questions only
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(UR.BadgeCount, 0) AS TotalBadges,
    COALESCE(UR.AvgPostScore, 0) AS AveragePostScore,
    RP.Title AS PostTitle,
    RP.ViewCount AS PostViewCount,
    PCR.CloseReason AS RecentCloseReason,
    PCR.CloseCount AS TotalCloseActions
FROM Users U
LEFT JOIN UserReputationCTE UR ON U.Id = UR.UserId
INNER JOIN RankedPosts RP ON U.Id = RP.OwnerUserId
LEFT JOIN PostCloseReasons PCR ON RP.PostId = PCR.PostId AND PCR.CloseCount = (
    SELECT MAX(CloseCount) 
    FROM PostCloseReasons
    WHERE PostId = RP.PostId
)
WHERE 
    U.Reputation > 1000 
    AND (UR.AvgPostScore > 10 OR UR.BadgeCount > 3)
ORDER BY 
    U.Reputation DESC,
    RP.ViewCount DESC;

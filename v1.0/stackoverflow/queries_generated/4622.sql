WITH UserBadgeCounts AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldCount,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverCount,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeCount
    FROM Badges
    GROUP BY UserId
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(PH.CloseReason, 'Not Closed') AS CloseReason,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN (
        SELECT 
            PostId,
            STRING_AGG(CASE WHEN PostHistoryTypeId = 10 THEN 'Closed' ELSE 'Reopened' END, ', ') AS CloseReason
        FROM PostHistory
        WHERE PostHistoryTypeId IN (10, 11)
        GROUP BY PostId
    ) PH ON P.Id = PH.PostId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    UBC.GoldCount,
    UBC.SilverCount,
    UBC.BronzeCount,
    PD.PostId,
    PD.Title,
    PD.CreationDate,
    PD.Score,
    PD.CloseReason
FROM Users U
LEFT JOIN UserBadgeCounts UBC ON U.Id = UBC.UserId
LEFT JOIN PostDetails PD ON U.Id = PD.OwnerDisplayName
WHERE PD.RecentPostRank <= 5 OR PD.PostId IS NULL
ORDER BY U.Reputation DESC, PD.Score DESC NULLS LAST
LIMIT 50
UNION ALL
SELECT 
    NULL AS UserId,
    'Aggregate' AS DisplayName,
    SUM(U.Reputation) AS TotalReputation,
    SUM(UBC.GoldCount) AS TotalGoldCount,
    SUM(UBC.SilverCount) AS TotalSilverCount,
    SUM(UBC.BronzeCount) AS TotalBronzeCount,
    COUNT(DISTINCT PD.PostId) AS TotalPosts,
    NULL AS Title,
    NULL AS CreationDate,
    NULL AS Score,
    NULL AS CloseReason
FROM Users U
JOIN UserBadgeCounts UBC ON U.Id = UBC.UserId
JOIN PostDetails PD ON U.Id = PD.OwnerDisplayName;

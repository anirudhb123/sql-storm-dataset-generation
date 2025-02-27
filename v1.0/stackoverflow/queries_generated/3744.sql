WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 AND 
        P.CreationDate >= (CURRENT_DATE - INTERVAL '1 year')
),
ClosedPosts AS (
    SELECT 
        PH.PostId, 
        PH.CreationDate AS CloseDate,
        COALESCE(CRT.Name, 'Unknown') AS CloseReason
    FROM 
        PostHistory PH
    LEFT JOIN 
        CloseReasonTypes CRT ON PH.Comment::int = CRT.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) 
),
UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(COALESCE(B.Class, 0)) AS TotalBadges,
        AVG(U.Reputation) AS AvgReputation
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    RP.Title,
    RP.ViewCount,
    RP.Score,
    U.DisplayName,
    U.AvgReputation,
    COUNT(DISTINCT CP.PostId) AS TotalClosedPosts,
    STRING_AGG(DISTINCT CP.CloseReason, ', ') AS ClosedReasons
FROM 
    RankedPosts RP
JOIN 
    Users U ON RP.OwnerUserId = U.Id
LEFT JOIN 
    ClosedPosts CP ON RP.PostId = CP.PostId
WHERE 
    RP.PostRank <= 3
GROUP BY 
    RP.PostId, RP.Title, RP.ViewCount, RP.Score, U.DisplayName, U.AvgReputation
ORDER BY 
    RP.Score DESC, TotalClosedPosts DESC
LIMIT 10;

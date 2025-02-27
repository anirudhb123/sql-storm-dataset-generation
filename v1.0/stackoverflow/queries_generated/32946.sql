WITH RecursiveUserPosts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        P.Id AS PostId,
        P.CreationDate,
        P.Title,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Users U
    INNER JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 1000
),
PostWithBadges AS (
    SELECT 
        RP.UserId,
        RP.DisplayName,
        RP.PostId,
        RP.Title,
        RP.Score,
        COALESCE(B.Class, 0) AS BadgeClass
    FROM 
        RecursiveUserPosts RP
    LEFT JOIN 
        Badges B ON RP.UserId = B.UserId AND B.Date >= RP.CreationDate
    WHERE 
        RP.PostRank <= 5
),
PostScoreStats AS (
    SELECT 
        P.UserId,
        AVG(P.Score) AS AvgScore,
        COUNT(P.PostId) AS PostCount
    FROM 
        PostWithBadges P
    GROUP BY 
        P.UserId
),
RecentClosedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        PH.CreationDate AS CloseDate,
        C.Name AS CloseReason
    FROM 
        Posts P
    INNER JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId = 10
    LEFT JOIN 
        CloseReasonTypes C ON CAST(PH.Comment AS INT) = C.Id
    WHERE 
        PH.CreationDate > CURRENT_DATE - INTERVAL '1 month'
),
FinalResult AS (
    SELECT 
        U.DisplayName,
        S.AvgScore,
        S.PostCount,
        R.CloseDate,
        R.CloseReason
    FROM 
        PostScoreStats S
    JOIN 
        Users U ON S.UserId = U.Id
    LEFT JOIN 
        RecentClosedPosts R ON R.PostId IN (
            SELECT 
                PostId 
            FROM 
                Posts 
            WHERE 
                OwnerUserId = U.Id
        )
    WHERE 
        S.AvgScore IS NOT NULL
)
SELECT 
    DisplayName,
    COALESCE(PostCount, 0) AS TotalPosts,
    COALESCE(AvgScore, 0) AS AverageScore,
    COALESCE(CloseDate, 'No recent closures') AS LastClosedDate,
    COALESCE(CloseReason, 'N/A') AS ClosureReason
FROM 
    FinalResult
ORDER BY 
    TotalPosts DESC, AvgScore DESC;

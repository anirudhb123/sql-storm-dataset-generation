WITH UserPostCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostScoreDetails AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Score,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC, P.CreationDate ASC) AS PostRank,
        AVG(COALESCE(PV.Score, 0)) OVER (PARTITION BY P.Id) AS AvgVoteScore
    FROM 
        Posts P
    LEFT JOIN 
        Votes PV ON P.Id = PV.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),
ClosedPostReasons AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        MAX(CASE WHEN PH.PostHistoryTypeId = 10 THEN CT.Name END) AS CloseReason,
        COUNT(*) AS CloseOccurrences
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CT ON PH.Comment::int = CT.Id
    GROUP BY 
        PH.PostId, PH.CreationDate
),
TopPosters AS (
    SELECT 
        UPC.UserId,
        UPC.DisplayName,
        UPC.PostCount,
        ROW_NUMBER() OVER (ORDER BY UPC.PostCount DESC) AS UserRank
    FROM 
        UserPostCounts UPC
    WHERE 
        UPC.PostCount > 0
),
FinalResults AS (
    SELECT 
        TP.UserId,
        TP.DisplayName,
        TP.PostCount,
        PP.PostId,
        PP.Score,
        PP.CreationDate,
        PP.PostRank,
        CPR.CloseReason,
        CPR.CloseOccurrences
    FROM 
        TopPosters TP
    LEFT JOIN 
        PostScoreDetails PP ON TP.UserId = PP.OwnerUserId
    LEFT JOIN 
        ClosedPostReasons CPR ON PP.PostId = CPR.PostId
    WHERE 
        TP.UserRank <= 10
)

SELECT 
    FR.DisplayName,
    FR.PostCount,
    SUM(CASE WHEN FR.Score IS NULL THEN 0 ELSE FR.Score END) AS TotalScore,
    COUNT(DISTINCT FR.PostId) AS UniquePosts,
    STRING_AGG(FR.CloseReason, ', ') AS CloseReasons,
    COUNT(FR.CloseOccurrences) AS TotalCloseActions
FROM 
    FinalResults FR
GROUP BY 
    FR.DisplayName, FR.PostCount
ORDER BY 
    TotalScore DESC, FR.DisplayName
LIMIT 100;

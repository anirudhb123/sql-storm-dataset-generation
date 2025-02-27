WITH RECURSIVE UserPostCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY COUNT(P.Id) DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        UserId, 
        PostCount, 
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserPostCounts
    WHERE 
        PostCount > 0
),
RecentPostHistory AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.CreationDate,
        PH.PostHistoryTypeId,
        PH.Comment,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS LatestChange
    FROM 
        PostHistory PH
    WHERE 
        PH.CreationDate > NOW() - INTERVAL '30 days'
),
PostWithLatestHistory AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        COALESCE(RPH.Comment, 'No recent changes') AS RecentChange,
        COALESCE(RPH.CreationDate, P.CreationDate) AS LastActivityDate
    FROM 
        Posts P
    LEFT JOIN 
        RecentPostHistory RPH ON P.Id = RPH.PostId AND RPH.LatestChange = 1
)
SELECT 
    U.DisplayName,
    TU.PostCount,
    TU.TotalScore,
    PWLH.PostId,
    PWLH.Title,
    PWLH.Score,
    PWLH.RecentChange,
    PWLH.LastActivityDate
FROM 
    TopUsers TU
JOIN 
    Users U ON TU.UserId = U.Id
LEFT JOIN 
    PostWithLatestHistory PWLH ON PWLH.PostId IN (
        SELECT 
            PostId 
        FROM 
            Posts 
        WHERE 
            OwnerUserId = U.Id
    )
WHERE 
    TU.ScoreRank <= 10
ORDER BY 
    TU.TotalScore DESC, 
    PWLH.LastActivityDate DESC;

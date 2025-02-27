WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(P.Score) AS TotalScore,
        AVG(COALESCE(P.ViewCount, 0)) AS AverageViewCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.Reputation
),
TopTags AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%' 
    GROUP BY 
        T.Id, T.TagName
    HAVING 
        COUNT(DISTINCT P.Id) > 5
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        STRING_AGG(B.Name, ', ') AS BadgeList,
        MAX(B.Class) AS MaxBadgeClass
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostHistoryAggregation AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS ChangeCount,
        MAX(PH.CreationDate) AS LastChangeDate,
        COUNT(DISTINCT PH.UserId) AS UniqueEditors
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    UR.TotalPosts,
    UR.TotalScore,
    UR.AverageViewCount,
    UB.BadgeList,
    UB.MaxBadgeClass,
    TT.TagName,
    PHA.ChangeCount,
    COALESCE(PHA.UniqueEditors, 0) AS TotalEditors,
    CASE 
        WHEN UR.Reputation > 1000 THEN 'Experienced'
        WHEN UR.Reputation BETWEEN 500 AND 1000 THEN 'Intermediate'
        ELSE 'Novice'
    END AS UserLevel,
    CASE 
        WHEN PH.LastChangeDate > SYSTIMESTAMP - INTERVAL '30' DAY THEN 'Recently Updated'
        ELSE 'No Recent Activity'
    END AS PostActivityStatus
FROM 
    UserReputation UR
JOIN 
    Users U ON U.Id = UR.UserId
LEFT JOIN 
    UserBadges UB ON U.Id = UB.UserId
LEFT JOIN 
    TopTags TT ON TT.PostCount > 10
LEFT JOIN 
    PostHistoryAggregation PH ON PH.PostId IN (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = U.Id)
WHERE 
    U.Reputation IS NOT NULL
    AND U.DisplayName IS NOT NULL
ORDER BY 
    U.Reputation DESC,
    TT.PostCount DESC
FETCH FIRST 100 ROWS ONLY;

WITH RecursivePostCTE AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.ViewCount,
        P.LastActivityDate,
        0 AS Level
    FROM 
        Posts P
    WHERE 
        P.ParentId IS NULL

    UNION ALL

    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.ViewCount,
        P.LastActivityDate,
        Level + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostCTE RP ON P.ParentId = RP.PostId
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        SUM(P.ViewCount) AS TotalViews,
        COUNT(P.Id) AS TotalPosts,
        COUNT(DISTINCT BH.Id) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges BH ON U.Id = BH.UserId
    GROUP BY 
        U.Id, U.Reputation
),
MaxPostViews AS (
    SELECT 
        MAX(ViewCount) AS MaxViews
    FROM 
        Posts
),
PostClosureHistory AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount,
        ARRAY_AGG(DISTINCT C.Name) AS CloseReasons
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes C ON PH.Comment::int = C.Id
    WHERE 
        PH.PostHistoryTypeId = 10 -- Closed posts
    GROUP BY 
        PH.PostId
)

SELECT 
    RP.PostId,
    RP.Title,
    U.DisplayName,
    U.Reputation,
    US.TotalViews,
    PS.MaxViews AS OverallMaxViews,
    PH.CloseCount,
    PH.CloseReasons,
    CASE 
        WHEN PH.CloseCount > 0 THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus,
    ROW_NUMBER() OVER (PARTITION BY RP.OwnerUserId ORDER BY RP.LastActivityDate DESC) AS UserPostRank
FROM 
    RecursivePostCTE RP
JOIN 
    Users U ON RP.OwnerUserId = U.Id
JOIN 
    UserStats US ON U.Id = US.UserId
JOIN 
    MaxPostViews PS ON 1=1
LEFT JOIN 
    PostClosureHistory PH ON RP.PostId = PH.PostId
WHERE 
    U.Reputation > (SELECT AVG(Reputation) FROM Users) -- Filtering users above average reputation
    AND RP.Level <= 1 -- Limit to direct questions and one level of answers
ORDER BY 
    U.Reputation DESC,
    RP.ViewCount DESC;

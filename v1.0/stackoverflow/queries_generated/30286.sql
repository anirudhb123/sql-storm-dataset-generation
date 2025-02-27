WITH RECURSIVE UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        B.Name AS BadgeName,
        B.Class,
        B.Date AS BadgeDate,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY B.Date DESC) AS BadgeRank
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(P.ViewCount) AS TotalViews,
        SUM(COALESCE(V.CreationDate IS NOT NULL, 0)) AS TotalVotes,
        COUNT(DISTINCT C.Id) AS TotalComments,
        AVG(P.Score) AS AverageScore
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        PH.UserId,
        COUNT(P.Id) AS ClosedPostCount,
        SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosedByVotes,
        SUM(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenedCount
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON P.Id = PH.PostId
    WHERE 
        PH.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        PH.UserId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COALESCE(S.TotalPosts, 0) AS TotalPosts,
    COALESCE(S.TotalViews, 0) AS TotalViews,
    COALESCE(S.TotalVotes, 0) AS TotalVotes,
    COALESCE(S.TotalComments, 0) AS TotalComments,
    COALESCE(S.AverageScore, 0) AS AverageScore,
    COALESCE(C.ClosedPostCount, 0) AS ClosedPostCount,
    COALESCE(C.ClosedByVotes, 0) AS ClosedByVotes,
    COALESCE(C.ReopenedCount, 0) AS ReopenedCount,
    B.BadgeName,
    B.Class AS BadgeClass
FROM 
    Users U
LEFT JOIN 
    PostStatistics S ON U.Id = S.OwnerUserId
LEFT JOIN 
    ClosedPosts C ON U.Id = C.UserId
LEFT JOIN 
    UserBadges B ON U.Id = B.UserId AND B.BadgeRank = 1
WHERE 
    COALESCE(S.TotalPosts, 0) > 0
    OR COALESCE(C.ClosedPostCount, 0) > 0
ORDER BY 
    TotalViews DESC
LIMIT 10;

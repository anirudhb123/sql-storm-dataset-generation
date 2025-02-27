-- Performance Benchmarking Query for StackOverflow Schema

WITH PostStats AS (
    SELECT 
        PT.Name AS PostType,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViewCount,
        AVG(COALESCE(P.Score, 0)) AS AvgScore,
        AVG(COALESCE(P.ViewCount, 0)) AS AvgViewCount,
        COUNT(DISTINCT P.OwnerUserId) AS UniqueUsers
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    GROUP BY 
        PT.Name
),
UserStats AS (
    SELECT 
        U.DisplayName,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.DisplayName
),
BadgeStats AS (
    SELECT 
        B.Name AS BadgeName,
        COUNT(B.Id) AS UsersWithBadge
    FROM 
        Badges B
    GROUP BY 
        B.Name
)

SELECT 
    PS.PostType,
    PS.PostCount,
    PS.TotalScore,
    PS.TotalViewCount,
    PS.AvgScore,
    PS.AvgViewCount,
    PS.UniqueUsers,
    US.DisplayName,
    US.TotalViews,
    US.TotalScore,
    US.PostCount,
    BS.BadgeName,
    BS.UsersWithBadge
FROM 
    PostStats PS
LEFT JOIN 
    UserStats US ON PS.UniqueUsers > 0
LEFT JOIN 
    BadgeStats BS ON BS.UsersWithBadge > 0
ORDER BY 
    PS.PostType;

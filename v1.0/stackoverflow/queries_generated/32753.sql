WITH RecentUserActions AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        SUM(V.BountyAmount) AS TotalBounties,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY MAX(COALESCE(P.CreationDate, C.CreationDate))) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalComments,
        TotalBadges,
        TotalBounties
    FROM 
        RecentUserActions
    WHERE 
        UserRank <= 10
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostsCount,
        AVG(P.Score) AS AverageScore,
        MAX(P.ViewCount) AS MaxViewCount,
        MIN(P.CreationDate) AS FirstPostDate,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
ActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(PS.PostsCount, 0) AS PostsCount,
        COALESCE(PS.AverageScore, 0) AS AverageScore,
        COALESCE(PS.MaxViewCount, 0) AS MaxViewCount,
        DENSE_RANK() OVER (ORDER BY COALESCE(PS.AverageScore, 0) DESC) AS ScoreRank
    FROM 
        Users U
    LEFT JOIN 
        PostStatistics PS ON U.Id = PS.OwnerUserId
)
SELECT 
    TU.DisplayName,
    TU.TotalPosts,
    TU.TotalComments,
    TU.TotalBadges,
    TU.TotalBounties,
    AU.PostsCount,
    AU.AverageScore,
    AU.MaxViewCount,
    AU.ScoreRank
FROM 
    TopUsers TU
JOIN 
    ActiveUsers AU ON TU.UserId = AU.UserId
ORDER BY 
    TU.TotalBounties DESC, AU.AverageScore DESC;

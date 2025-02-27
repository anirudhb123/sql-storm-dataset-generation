WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostsCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        COUNT(DISTINCT C.Id) AS CommentsCount,
        COUNT(DISTINCT B.Id) AS BadgesCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostsCount,
        TotalViews,
        TotalScore,
        CommentsCount,
        BadgesCount,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC, TotalViews DESC, TotalScore DESC) AS Rank
    FROM 
        UserStats
)
SELECT 
    Rank,
    DisplayName,
    Reputation,
    PostsCount,
    TotalViews,
    TotalScore,
    CommentsCount,
    BadgesCount
FROM 
    TopUsers
WHERE 
    Rank <= 10
ORDER BY 
    Rank;

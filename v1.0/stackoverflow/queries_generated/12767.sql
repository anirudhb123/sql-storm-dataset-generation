-- Performance Benchmarking Query

WITH PostsStats AS (
    SELECT 
        P.PostTypeId,
        COUNT(*) AS TotalPosts,
        AVG(P.ViewCount) AS AvgViewCount,
        AVG(P.Score) AS AvgScore,
        SUM(COALESCE(P.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(P.CommentCount, 0)) AS TotalComments,
        SUM(COALESCE(P.FavoriteCount, 0)) AS TotalFavorites,
        MAX(P.CreationDate) AS LastPostDate,
        MIN(P.CreationDate) AS FirstPostDate
    FROM 
        Posts P
    GROUP BY 
        P.PostTypeId
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        SUM(V.BountyAmount) AS TotalBounty,
        COUNT(DISTINCT P.Id) AS TotalPostsByUser,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViewsByUser
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
)
SELECT 
    PS.PostTypeId,
    PT.Name AS PostTypeName,
    PS.TotalPosts,
    PS.AvgViewCount,
    PS.AvgScore,
    PS.TotalAnswers,
    PS.TotalComments,
    PS.TotalFavorites,
    PS.LastPostDate,
    PS.FirstPostDate,
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.TotalBadges,
    US.TotalBounty,
    US.TotalPostsByUser,
    US.TotalViewsByUser
FROM 
    PostsStats PS
JOIN 
    PostTypes PT ON PS.PostTypeId = PT.Id
JOIN 
    UserStats US ON US.TotalPostsByUser > 0
ORDER BY 
    PS.TotalPosts DESC, US.TotalViewsByUser DESC;

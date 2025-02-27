-- Performance benchmarking query for StackOverflow schema

WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(B.Id) AS TotalBadges,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        P.Tags,
        P.LastActivityDate,
        U.DisplayName AS OwnerDisplayName
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.TotalBadges,
    US.TotalViews,
    US.TotalScore,
    US.TotalPosts,
    US.TotalComments,
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.Score,
    PS.AnswerCount,
    PS.CommentCount,
    PS.FavoriteCount,
    PS.Tags,
    PS.LastActivityDate
FROM 
    UserStats US
JOIN 
    PostStats PS ON US.UserId = PS.OwnerUserId
ORDER BY 
    US.Reputation DESC, 
    PS.Score DESC
LIMIT 100;  -- Change this limit as per the benchmarking needs

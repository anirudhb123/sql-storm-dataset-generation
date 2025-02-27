-- Performance Benchmarking Query

WITH PostStats AS (
    SELECT 
        PT.Name AS PostType,
        COUNT(P.Id) AS TotalPosts,
        COALESCE(AVG(P.Score), 0) AS AvgScore,
        COALESCE(AVG(P.ViewCount), 0) AS AvgViewCount,
        COALESCE(AVG(P.AnswerCount), 0) AS AvgAnswerCount,
        COALESCE(AVG(P.CommentCount), 0) AS AvgCommentCount,
        COALESCE(AVG(P.FavoriteCount), 0) AS AvgFavoriteCount
    FROM 
        Posts P
    INNER JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    GROUP BY 
        PT.Name
),
UserStats AS (
    SELECT 
        U.DisplayName,
        SUM(B.Class = 1 OR B.Class = 2 OR B.Class = 3) AS TotalBadges,
        AVG(U.Reputation) AS AvgReputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COALESCE(SUM(V.CreationDate IS NOT NULL), 0) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.DisplayName
)
SELECT 
    PS.PostType,
    PS.TotalPosts,
    PS.AvgScore,
    PS.AvgViewCount,
    PS.AvgAnswerCount,
    PS.AvgCommentCount,
    PS.AvgFavoriteCount,
    US.DisplayName,
    US.TotalBadges,
    US.AvgReputation,
    US.TotalPosts AS UserTotalPosts,
    US.TotalVotes
FROM 
    PostStats PS
JOIN 
    UserStats US ON PS.TotalPosts > 0  -- Just to ensure some relation for analysis
ORDER BY 
    PS.PostType;

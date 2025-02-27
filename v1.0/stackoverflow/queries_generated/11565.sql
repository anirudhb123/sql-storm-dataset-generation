-- Performance benchmarking query to analyze Post and User activity

WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COALESCE(A.AverageScore, 0) AS AverageScore
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            P.Id,
            AVG(V.Score) AS AverageScore
        FROM 
            Posts P
        INNER JOIN 
            Votes V ON P.Id = V.PostId
        GROUP BY 
            P.Id
    ) A ON P.Id = A.Id
)

SELECT 
    UA.DisplayName,
    UA.TotalPosts,
    UA.TotalComments,
    UA.PositivePosts,
    UA.NegativePosts,
    UA.TotalBadges,
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.AverageScore
FROM 
    UserActivity UA
JOIN 
    PostStatistics PS ON UA.UserId = PS.PostId
ORDER BY 
    UA.TotalPosts DESC,
    PS.ViewCount DESC;

-- Performance benchmarking query for Stack Overflow schema

WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        COUNT(C.Id) AS TotalComments,
        SUM(V.BountyAmount) AS TotalBounties,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),

PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        P.CreationDate AS PostCreationDate,
        P.LastActivityDate
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= DATEADD(year, -1, GETDATE())
)

SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.TotalPosts,
    UA.TotalComments,
    UA.TotalBounties,
    UA.LastPostDate,
    PS.PostId,
    PS.Title,
    PS.ViewCount,
    PS.Score,
    PS.AnswerCount,
    PS.CommentCount,
    PS.FavoriteCount,
    PS.PostCreationDate,
    PS.LastActivityDate
FROM 
    UserActivity UA
LEFT JOIN 
    PostStatistics PS ON PS.PostId IN (SELECT PostId FROM Posts WHERE OwnerUserId = UA.UserId)
ORDER BY 
    UA.TotalPosts DESC, 
    UA.LastPostDate DESC;

-- Performance Benchmarking Query

WITH UserPosts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),

PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        PT.Name AS PostType,
        U.DisplayName AS Owner,
        COUNT(C.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, PT.Name, U.DisplayName
)

SELECT 
    UP.UserId,
    UP.DisplayName,
    UP.PostCount,
    UP.TotalScore,
    UP.TotalViews,
    (SELECT COUNT(*) FROM PostDetails PD WHERE PD.Owner = UP.DisplayName) AS TotalPostDetails,
    (SELECT AVG(Score) FROM PostDetails WHERE Owner = UP.DisplayName) AS AvgPostScore,
    (SELECT AVG(ViewCount) FROM PostDetails WHERE Owner = UP.DisplayName) AS AvgPostViews
FROM 
    UserPosts UP
ORDER BY 
    UP.TotalScore DESC
LIMIT 100;

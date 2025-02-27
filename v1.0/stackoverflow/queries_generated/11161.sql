-- Performance Benchmarking Query
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBounty
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
        P.Score,
        P.ViewCount,
        STUFF((SELECT ', ' + T.TagName
               FROM Tags T
               WHERE P.Tags LIKE '%' + T.TagName + '%'
               FOR XML PATH('')), 1, 2, '') AS Tags
    FROM 
        Posts P
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.PostCount,
    U.CommentCount,
    U.TotalBounty,
    P.PostId,
    P.Title,
    P.Score,
    P.ViewCount,
    P.Tags
FROM 
    UserStatistics U
JOIN 
    PostStatistics P ON P.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = U.UserId)
ORDER BY 
    U.PostCount DESC, 
    U.TotalBounty DESC;

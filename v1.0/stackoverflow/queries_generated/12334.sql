WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN A.Id IS NOT NULL THEN 1 END) AS AnswerCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(B.Class) AS TotalBadges,
        SUM(V.BountyAmount) AS TotalBountyRewards,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(P.ViewCount) AS TotalPostViews
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.CommentCount,
    PS.AnswerCount,
    US.UserId,
    US.DisplayName,
    US.TotalBadges,
    US.TotalBountyRewards,
    US.TotalPosts,
    US.TotalPostViews
FROM 
    PostStats PS
JOIN 
    Users US ON PS.CreationDate >= US.CreationDate
ORDER BY 
    PS.ViewCount DESC, 
    PS.Score DESC
LIMIT 100;

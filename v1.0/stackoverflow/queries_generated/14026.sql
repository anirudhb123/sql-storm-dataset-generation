-- Performance Benchmarking Query

WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
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
        U.Id
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        H.UserId AS LastEditedBy,
        H.LastEditDate
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory H ON P.Id = H.PostId
    ORDER BY 
        P.LastActivityDate DESC
),
BadgeStats AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS TotalBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)

SELECT 
    U.DisplayName AS UserName,
    U.Reputation,
    US.TotalPosts,
    US.TotalComments,
    US.TotalBounty,
    PS.Title AS LastPostTitle,
    PS.Score AS LastPostScore,
    PS.ViewCount AS LastPostViewCount,
    BS.TotalBadges
FROM 
    UserStats US
JOIN 
    Users U ON US.UserId = U.Id
LEFT JOIN 
    PostStats PS ON PS.LastEditedBy = U.Id
LEFT JOIN 
    BadgeStats BS ON BS.UserId = U.Id
ORDER BY 
    US.Reputation DESC, 
    US.TotalPosts DESC;

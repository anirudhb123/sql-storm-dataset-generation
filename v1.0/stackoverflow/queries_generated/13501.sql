-- Performance benchmarking query for StackOverflow schema
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
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
        U.Id, U.Reputation
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        MAX(CREATION_DATE) AS LastActivityDate
    FROM 
        Posts P
    GROUP BY 
        P.Id, P.PostTypeId, P.ViewCount, P.Score, P.AnswerCount, P.CommentCount, P.FavoriteCount
),
CombinedStats AS (
    SELECT 
        U.UserId,
        U.Reputation,
        U.PostCount,
        U.CommentCount,
        U.TotalBounty,
        PS.PostId,
        PS.PostTypeId,
        PS.ViewCount,
        PS.Score,
        PS.AnswerCount,
        PS.CommentCount AS PostCommentCount,
        PS.FavoriteCount,
        PS.LastActivityDate
    FROM 
        UserStats U
    INNER JOIN 
        PostStats PS ON U.UserId = PS.OwnerUserId
)

SELECT 
    UserId,
    Reputation,
    PostCount,
    CommentCount,
    TotalBounty,
    PostId,
    PostTypeId,
    ViewCount,
    Score,
    AnswerCount,
    PostCommentCount,
    FavoriteCount,
    LastActivityDate
FROM 
    CombinedStats
ORDER BY 
    Reputation DESC, PostCount DESC
LIMIT 100;

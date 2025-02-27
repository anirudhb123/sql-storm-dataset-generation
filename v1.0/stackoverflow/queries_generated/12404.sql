-- Performance benchmarking query to analyze user activity and post interactions
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostsCount,
        COUNT(DISTINCT C.Id) AS CommentsCount,
        SUM(V.CreationDate IS NOT NULL) AS VotesCount,
        SUM(B.Id IS NOT NULL) AS BadgesCount,
        SUM(P.Score) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),

PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        P.Score,
        P.AnswerCount,
        P.CommentCount,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation AS OwnerReputation
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.PostsCount,
    U.CommentsCount,
    U.VotesCount,
    U.BadgesCount,
    U.TotalScore,
    P.PostId,
    P.Title,
    P.ViewCount,
    P.CreationDate,
    P.Score AS PostScore,
    P.AnswerCount,
    P.CommentCount,
    P.OwnerDisplayName,
    P.OwnerReputation
FROM 
    UserActivity U
LEFT JOIN 
    PostMetrics P ON P.OwnerDisplayName = U.DisplayName
ORDER BY 
    U.Reputation DESC, U.PostsCount DESC;

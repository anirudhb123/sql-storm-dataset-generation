-- Performance benchmarking query to analyze post statistics and user interactions
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        U.Reputation AS OwnerReputation,
        COALESCE(COUNT(DISTINCT C.Id), 0) AS TotalComments,
        COALESCE(COUNT(DISTINCT V.Id), 0) AS TotalVotes
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, U.Reputation
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        SUM(P.Score) AS TotalPostScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    S.PostId,
    S.Title,
    S.CreationDate,
    S.Score,
    S.ViewCount,
    S.AnswerCount,
    S.CommentCount,
    S.FavoriteCount,
    S.OwnerReputation,
    S.TotalComments,
    S.TotalVotes,
    U.UserId,
    U.DisplayName,
    U.Reputation AS UserReputation,
    U.TotalPosts,
    U.TotalBadges,
    U.TotalPostScore
FROM 
    PostStats S
JOIN 
    UserStats U ON S.OwnerReputation = U.Reputation
ORDER BY 
    S.ViewCount DESC, S.Score DESC;

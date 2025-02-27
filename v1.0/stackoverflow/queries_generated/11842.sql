-- Performance Benchmarking Query
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(VoteValue) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        (SELECT 
            V.UserId, 
            V.PostId, 
            CASE 
                WHEN V.VoteTypeId = 2 THEN 1
                WHEN V.VoteTypeId = 3 THEN -1
                ELSE 0
            END AS VoteValue
        FROM 
            Votes V) AS V ON P.Id = V.PostId
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
        P.FavoriteCount,
        P.OwnerUserId,
        U.DisplayName AS AuthorName,
        COUNT(C.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, U.DisplayName
)

SELECT 
    U.DisplayName AS UserName,
    U.Reputation AS UserReputation,
    U.PostCount,
    U.BadgeCount,
    U.TotalVotes,
    P.Title AS PostTitle,
    P.Score AS PostScore,
    P.ViewCount AS PostViewCount,
    P.AnswerCount AS PostAnswerCount,
    P.CommentCount AS PostCommentCount,
    P.FavoriteCount AS PostFavoriteCount,
    P.AuthorName AS PostAuthor
FROM 
    UserStats U
JOIN 
    PostStats P ON U.UserId = P.OwnerUserId
ORDER BY 
    U.Reputation DESC, P.Score DESC
LIMIT 100;

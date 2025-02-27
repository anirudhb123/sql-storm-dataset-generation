-- Performance benchmarking query to analyze posts, votes, and users activity

WITH PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        U.Reputation AS OwnerReputation,
        COUNT(V.Id) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year' -- Filter for posts created in the last year
    GROUP BY 
        P.Id, U.Reputation
),

UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        SUM(B.Reputation) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)

SELECT 
    PA.PostId,
    PA.Title,
    PA.CreationDate,
    PA.Score,
    PA.ViewCount,
    PA.AnswerCount,
    PA.CommentCount,
    PA.OwnerReputation,
    PA.VoteCount,
    UA.UserId,
    UA.DisplayName,
    UA.PostCount AS UserPostCount,
    UA.VoteCount AS UserVoteCount,
    UA.TotalBadges
FROM 
    PostActivity PA
JOIN 
    UserActivity UA ON PA.OwnerReputation = UA.VoteCount -- Join post and user activity based on common metrics
ORDER BY 
    PA.ViewCount DESC, PA.Score DESC; -- Order by views and score for performance insights

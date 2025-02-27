-- Performance benchmarking query to analyze user activity and post engagement

WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(COALESCE(V.Count, 0)) AS TotalVotes,
        SUM(COALESCE(B.Id, 0)) AS TotalBadges
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
        U.Id, U.Reputation
),
PostEngagement AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        COALESCE(V.BountyAmount, 0) AS BountyAmount,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.AnswerCount, 
        P.CommentCount, P.FavoriteCount, V.BountyAmount
),
ActivitySummary AS (
    SELECT 
        U.UserId,
        U.Reputation,
        U.TotalPosts,
        U.TotalComments,
        U.TotalVotes,
        U.TotalBadges,
        P.PostId,
        P.Title AS PostTitle,
        P.CreationDate AS PostCreationDate,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount AS PostCommentCount,
        P.FavoriteCount,
        P.BountyAmount,
        P.TotalComments AS PostTotalComments
    FROM 
        UserActivity U
    JOIN 
        PostEngagement P ON U.UserId = P.PostId
)

SELECT 
    *
FROM 
    ActivitySummary
ORDER BY 
    Reputation DESC, TotalPosts DESC;

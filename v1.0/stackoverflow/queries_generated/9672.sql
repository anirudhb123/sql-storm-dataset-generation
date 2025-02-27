WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COUNT(DISTINCT B.Id) AS TotalBadges
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
), PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE(A.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON P.AcceptedAnswerId = A.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, A.AcceptedAnswerId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.TotalComments,
    U.TotalUpvotes,
    U.TotalDownvotes,
    U.TotalBadges,
    P.PostId,
    P.Title AS PostTitle,
    P.CreationDate AS PostCreationDate,
    P.Score AS PostScore,
    P.ViewCount AS PostViewCount,
    P.CommentCount AS PostCommentCount,
    P.VoteCount AS PostVoteCount,
    (SELECT STRING_AGG(T.TagName, ', ') 
     FROM Tags T 
     WHERE T.ExcerptPostId = P.PostId) AS PostTags
FROM 
    UserStats U
JOIN 
    PostStats P ON U.TotalPosts > 0
ORDER BY 
    U.Reputation DESC, P.Score DESC
LIMIT 100;

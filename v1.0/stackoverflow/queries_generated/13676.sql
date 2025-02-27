-- Performance Benchmarking Query

-- Measure the number of posts and their related comments, votes, and user activity.
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS UpVoteCount,  -- UpMod Votes
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS DownVoteCount -- DownMod Votes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),

UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT V.Id) AS TotalVotes
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
)

SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    U.DisplayName AS PostOwner,
    PS.CommentCount,
    PS.UpVoteCount,
    PS.DownVoteCount,
    UA.TotalPosts,
    UA.TotalComments,
    UA.TotalVotes
FROM 
    PostStats PS
JOIN 
    Users U ON PS.OwnerUserId = U.Id
JOIN 
    UserActivity UA ON U.Id = UA.UserId
ORDER BY 
    PS.CreationDate DESC
LIMIT 100; -- Limit results for benchmarking purposes

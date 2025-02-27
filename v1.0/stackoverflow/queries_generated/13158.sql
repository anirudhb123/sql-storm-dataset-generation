-- Performance benchmarking query for Stack Overflow schema
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.PostTypeId,
        COUNT(C.Id) AS CommentCount,
        SUM(V.VoteTypeId = 2) AS Upvotes,
        SUM(V.VoteTypeId = 3) AS Downvotes,
        SUM(V.VoteTypeId IN (6, 7)) AS CloseVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.OwnerUserId, P.PostTypeId
)
SELECT 
    U.DisplayName AS UserName,
    U.TotalPosts,
    U.TotalComments,
    U.TotalBounty,
    P.PostId,
    P.PostTypeId,
    P.CommentCount,
    P.Upvotes,
    P.Downvotes,
    P.CloseVotes
FROM 
    UserStats U
JOIN 
    PostStats P ON U.UserId = P.OwnerUserId
ORDER BY 
    U.TotalPosts DESC, U.TotalBounty DESC
LIMIT 100; -- Limiting to top 100 users by total posts

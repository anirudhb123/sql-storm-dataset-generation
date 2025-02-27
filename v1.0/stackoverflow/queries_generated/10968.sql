-- Performance benchmarking query for Stack Overflow schema

WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        SUM(V.VoteTypeId = 2) AS TotalUpvotes,  -- Upmod (upvotes)
        SUM(V.VoteTypeId = 3) AS TotalDownvotes -- Downmod (downvotes)
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON V.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalPosts,
    U.TotalComments,
    U.TotalBadges,
    U.TotalUpvotes,
    U.TotalDownvotes,
    (U.TotalUpvotes - U.TotalDownvotes) AS NetVotes,
    RANK() OVER (ORDER BY U.TotalPosts DESC) AS RankByPosts,
    RANK() OVER (ORDER BY U.TotalUpvotes DESC) AS RankByUpvotes
FROM 
    UserStats U
ORDER BY 
    U.TotalPosts DESC, U.TotalUpvotes DESC;

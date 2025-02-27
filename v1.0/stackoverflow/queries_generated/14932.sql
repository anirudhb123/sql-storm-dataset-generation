-- Performance benchmarking query for analyzing user engagement on posts
WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(V.VoteTypeId = 2) AS TotalUpvotes,
        SUM(V.VoteTypeId = 3) AS TotalDownvotes
    FROM 
        Users U 
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    *,
    (TotalUpvotes - TotalDownvotes) AS NetVotes,
    CASE 
        WHEN TotalPosts = 0 THEN 0
        ELSE (TotalComments::float / TotalPosts) END AS CommentPerPostRatio
FROM 
    UserEngagement
ORDER BY 
    TotalPosts DESC;

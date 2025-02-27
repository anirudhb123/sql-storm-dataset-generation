
WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(V.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalComments,
        TotalBounty,
        TotalUpvotes,
        TotalDownvotes,
        @row_number := IF(@prev_total_posts = TotalPosts, @row_number, @row_number + 1) AS rn,
        @prev_total_posts := TotalPosts
    FROM 
        UserEngagement, (SELECT @row_number := 0, @prev_total_posts := NULL) AS vars
    ORDER BY 
        TotalPosts DESC, TotalUpvotes DESC
)
SELECT 
    T.UserId,
    T.DisplayName,
    T.TotalPosts,
    T.TotalComments,
    T.TotalBounty,
    T.TotalUpvotes,
    T.TotalDownvotes,
    P.TotalPosts AS SimilarPostCount,
    T2.TopUserUpvotes
FROM 
    TopUsers T
JOIN (
    SELECT 
        U2.Id AS UserId,
        COUNT(P2.Id) AS TotalPosts
    FROM 
        Users U2
    JOIN 
        Posts P2 ON U2.Id = P2.OwnerUserId
    GROUP BY 
        U2.Id
) P ON T.TotalPosts > P.TotalPosts
JOIN (
    SELECT 
        UserId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS TopUserUpvotes
    FROM 
        Votes
    GROUP BY 
        UserId
) T2 ON T.UserId = T2.UserId
WHERE 
    T.rn <= 10;

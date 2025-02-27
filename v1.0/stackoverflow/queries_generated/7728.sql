WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalComments,
        TotalUpvotes,
        TotalDownvotes,
        TotalBadges,
        RANK() OVER (ORDER BY TotalUpvotes DESC) AS UpvoteRank,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM 
        UserStatistics
)
SELECT 
    T.DisplayName,
    T.TotalPosts,
    T.TotalComments,
    T.TotalUpvotes,
    T.TotalDownvotes,
    T.TotalBadges,
    T.UpvoteRank,
    T.PostRank
FROM 
    TopUsers T
WHERE 
    T.UpvoteRank <= 10 OR T.PostRank <= 10
ORDER BY 
    T.TotalPosts DESC, T.TotalUpvotes DESC;

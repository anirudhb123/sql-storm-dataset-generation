WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM 
        Users U
        LEFT JOIN Posts P ON U.Id = P.OwnerUserId
        LEFT JOIN Comments C ON U.Id = C.UserId
        LEFT JOIN Votes V ON U.Id = V.UserId
        LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalComments,
        TotalUpvotes,
        TotalDownvotes,
        TotalBadges,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC, TotalPosts DESC) AS RN
    FROM 
        UserActivity
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.TotalComments,
    U.TotalUpvotes,
    U.TotalDownvotes,
    U.TotalBadges
FROM 
    TopUsers U
WHERE 
    U.RN <= 10
ORDER BY 
    U.Reputation DESC;

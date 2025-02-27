WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        SUM(V.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
),
TopActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalComments,
        TotalBadges,
        TotalBounty,
        TotalUpvotes,
        TotalDownvotes,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC, TotalUpvotes DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalComments,
    TotalBadges,
    TotalBounty,
    TotalUpvotes,
    TotalDownvotes
FROM 
    TopActiveUsers
WHERE 
    Rank <= 10
ORDER BY 
    TotalPosts DESC, TotalUpvotes DESC;

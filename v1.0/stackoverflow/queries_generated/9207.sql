WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalComments,
        TotalBadges,
        TotalBounty,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank,
        RANK() OVER (ORDER BY TotalComments DESC) AS CommentRank
    FROM 
        UserActivity
)
SELECT 
    AU.DisplayName,
    AU.TotalPosts,
    AU.TotalComments,
    AU.TotalBadges,
    AU.TotalBounty,
    CASE 
        WHEN AU.PostRank = 1 THEN 'Top Poster'
        WHEN AU.CommentRank = 1 THEN 'Top Commenter'
        ELSE 'Active User' 
    END AS UserType
FROM 
    ActiveUsers AU
WHERE 
    AU.TotalPosts > 0 OR AU.TotalComments > 0
ORDER BY 
    AU.TotalPosts DESC, AU.TotalComments DESC;

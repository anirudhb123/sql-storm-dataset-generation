WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
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
        U.Reputation > 50
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
Ranking AS (
    SELECT
        UA.*,
        DENSE_RANK() OVER (ORDER BY UA.TotalPosts DESC, UA.TotalViews DESC, UA.TotalUpvotes DESC) AS Rank
    FROM 
        UserActivity UA
)
SELECT 
    R.Rank,
    R.DisplayName,
    R.Reputation,
    R.TotalPosts,
    R.TotalComments,
    R.TotalBadges,
    R.TotalUpvotes,
    R.TotalDownvotes,
    R.TotalViews
FROM 
    Ranking R
WHERE 
    R.Rank <= 10
ORDER BY 
    R.Rank;

WITH RECURSIVE UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        SUM(V.VoteTypeId = 2) AS TotalUpvotes,
        SUM(V.VoteTypeId = 3) AS TotalDownvotes,
        SUM(P.ViewCount) AS TotalViews,
        0 AS Level
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
    GROUP BY 
        U.Id, U.DisplayName

    UNION ALL

    SELECT 
        U.Id,
        U.DisplayName,
        UActivity.TotalPosts + COUNT(DISTINCT P.Id),
        UActivity.TotalComments + COUNT(DISTINCT C.Id),
        UActivity.TotalBadges + COUNT(DISTINCT B.Id),
        UActivity.TotalUpvotes + SUM(V.VoteTypeId = 2),
        UActivity.TotalDownvotes + SUM(V.VoteTypeId = 3),
        UActivity.TotalViews + SUM(P.ViewCount),
        UActivity.Level + 1
    FROM 
        Users U
    JOIN 
        UserActivity UActivity ON (U.Id = UActivity.UserId)
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, UActivity.TotalPosts, UActivity.TotalComments, 
        UActivity.TotalBadges, UActivity.TotalUpvotes, UActivity.TotalDownvotes,
        UActivity.TotalViews, UActivity.Level
)

SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.TotalPosts,
    UA.TotalComments,
    UA.TotalViews,
    UA.TotalBadges,
    UA.TotalUpvotes,
    UA.TotalDownvotes,
    CASE 
        WHEN UA.TotalPosts > 100 THEN 'Highly Active'
        WHEN UA.TotalPosts BETWEEN 51 AND 100 THEN 'Moderately Active'
        ELSE 'Less Active'
    END AS ActivityLevel
FROM 
    UserActivity UA
WHERE 
    UA.TotalPosts > 0
ORDER BY 
    UA.TotalViews DESC, UA.TotalUpvotes DESC;

WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId, 
        U.Reputation, 
        COUNT(DISTINCT P.Id) AS TotalPosts, 
        COUNT(DISTINCT C.Id) AS TotalComments, 
        COUNT(DISTINCT B.Id) AS TotalBadges,
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
    GROUP BY 
        U.Id, U.Reputation
), UserRankings AS (
    SELECT 
        Us.UserId,
        Us.Reputation,
        Us.TotalPosts,
        Us.TotalComments,
        Us.TotalBadges,
        Us.TotalUpvotes,
        Us.TotalDownvotes,
        RANK() OVER (ORDER BY Us.Reputation DESC) AS ReputationRank
    FROM 
        UserStatistics Us
)

SELECT 
    UR.UserId,
    UR.Reputation,
    UR.TotalPosts,
    UR.TotalComments,
    UR.TotalBadges,
    UR.TotalUpvotes,
    UR.TotalDownvotes,
    UR.ReputationRank,
    CASE 
        WHEN UR.TotalPosts > 50 AND UR.TotalBadges > 10 THEN 'Expert' 
        WHEN UR.TotalPosts BETWEEN 20 AND 50 THEN 'Experienced' 
        ELSE 'Novice' 
    END AS UserType
FROM 
    UserRankings UR
WHERE 
    UR.TotalPosts > 0
ORDER BY 
    UR.Reputation DESC, UR.TotalPosts DESC
LIMIT 100;

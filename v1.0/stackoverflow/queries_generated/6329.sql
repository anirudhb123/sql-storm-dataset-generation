WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
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
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        AVG(P.Score) AS AverageScore,
        MAX(P.ViewCount) AS MaxViewCount
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
EngagedUsers AS (
    SELECT 
        UE.UserId,
        UE.DisplayName,
        UE.TotalPosts,
        UE.TotalComments,
        UE.TotalBadges,
        UE.TotalUpvotes,
        UE.TotalDownvotes,
        PS.PostCount,
        PS.AverageScore,
        PS.MaxViewCount
    FROM 
        UserEngagement UE
    JOIN 
        PostStatistics PS ON UE.UserId = PS.OwnerUserId
)
SELECT 
    EU.DisplayName,
    EU.TotalPosts,
    EU.TotalComments,
    EU.TotalBadges,
    EU.TotalUpvotes,
    EU.TotalDownvotes,
    EU.PostCount,
    EU.AverageScore,
    EU.MaxViewCount
FROM 
    EngagedUsers EU
WHERE 
    EU.TotalPosts > 5
ORDER BY 
    EU.TotalUpvotes DESC, EU.TotalPosts DESC;

WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(CASE WHEN PH.PostId IS NOT NULL THEN 1 ELSE 0 END) AS TotalPostHistory
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
    LEFT JOIN 
        PostHistory PH ON U.Id = PH.UserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
MostActiveUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation,
        TotalPosts, 
        TotalComments, 
        TotalBadges, 
        TotalUpVotes, 
        TotalDownVotes,
        TotalPostHistory,
        RANK() OVER (ORDER BY TotalPosts DESC, TotalUpVotes DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.TotalComments,
    U.TotalBadges,
    U.TotalUpVotes,
    U.TotalDownVotes,
    U.TotalPostHistory
FROM 
    MostActiveUsers U
WHERE 
    U.Rank <= 10
ORDER BY 
    U.Rank;

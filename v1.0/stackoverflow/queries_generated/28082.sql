WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS TotalCloseVotes,
        SUM(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS TotalReopenVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
UserReputationRanking AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserActivity
),
ActiveUsers AS (
    SELECT 
        UAR.UserId,
        UAR.DisplayName,
        UAR.TotalPosts,
        UAR.TotalComments,
        UAR.TotalBadges,
        UAR.TotalCloseVotes,
        UAR.TotalReopenVotes,
        R.ReputationRank
    FROM 
        UserActivity UAR
    JOIN 
        UserReputationRanking R ON UAR.UserId = R.UserId
    WHERE 
        (UAR.TotalPosts > 0 OR UAR.TotalComments > 0)
)
SELECT 
    AU.UserId,
    AU.DisplayName,
    AU.TotalPosts,
    AU.TotalComments,
    AU.TotalBadges,
    AU.TotalCloseVotes,
    AU.TotalReopenVotes,
    AU.ReputationRank,
    CASE 
        WHEN AU.Reputation >= 1000 THEN 'Active Contributor'
        WHEN AU.Reputation >= 100 THEN 'Regular Contributor'
        ELSE 'New Contributor' 
    END AS ContributorLevel
FROM 
    ActiveUsers AU
ORDER BY 
    AU.ReputationRank;

WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        SUM(V.VoteTypeId = 2) AS UpVotes,
        SUM(V.VoteTypeId = 3) AS DownVotes,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties
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
        U.CreationDate < NOW() - INTERVAL '1 year'
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
UserRanked AS (
    SELECT 
        UA.*,
        RANK() OVER (ORDER BY TotalPosts DESC, UpVotes DESC) AS UserRank,
        ROW_NUMBER() OVER (PARTITION BY Reputation >= 1000 ORDER BY TotalComments DESC) AS ReputationGroup
    FROM 
        UserActivity UA
),
TopUsers AS (
    SELECT 
        U.*
    FROM 
        UserRanked U
    WHERE 
        U.UserRank <= 10
)

SELECT 
    TU.UserId,
    TU.DisplayName,
    TU.Reputation,
    TU.TotalPosts,
    TU.TotalComments,
    CASE 
        WHEN TU.ReputationGroup = 1 THEN 'Elite'
        WHEN TU.ReputationGroup = 0 THEN 'Rookie'
        ELSE 'Intermediate'
    END AS ReputationTier,
    COALESCE(HP.TotalHistoryChanges, 0) AS TotalHistoryChanges
FROM 
    TopUsers TU
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(*) AS TotalHistoryChanges
    FROM 
        PostHistory
    GROUP BY 
        UserId
) HP ON TU.UserId = HP.UserId
ORDER BY 
    TU.Reputation DESC, 
    TU.TotalPosts DESC;

This query performs a multi-step analysis of users who joined over a year ago, aggregating their posts, comments, badges, and votes. It employs common table expressions (CTEs) for clarity and organizes results by user rank and reputation tier, while also leveraging window functions for ranking. The outer join with the post history aggregates provides additional context about user activity in terms of post history changes. The case statements create a user-friendly categorization of users based on their reputation.

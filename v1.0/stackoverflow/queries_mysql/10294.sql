
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
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
        TotalUpVotes,
        TotalDownVotes,
        @rankReputation := IF(@prevReputation = Reputation, @rankReputation, @currentRank) AS ReputationRank,
        @prevReputation := Reputation,
        @currentRank := @currentRank + 1 AS Dummy 
    FROM 
        UserStats,
        (SELECT @currentRank := 1, @prevReputation := NULL, @rankReputation := NULL) AS vars
    ORDER BY 
        Reputation DESC
),
TopUsersPosts AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalComments,
        TotalUpVotes,
        TotalDownVotes,
        @rankPosts := IF(@prevPosts = TotalPosts, @rankPosts, @currentRankPosts) AS PostsRank,
        @prevPosts := TotalPosts,
        @currentRankPosts := @currentRankPosts + 1 AS Dummy 
    FROM 
        TopUsers,
        (SELECT @currentRankPosts := 1, @prevPosts := NULL, @rankPosts := NULL) AS vars
    ORDER BY 
        TotalPosts DESC
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    TotalPosts,
    TotalComments,
    TotalUpVotes,
    TotalDownVotes,
    ReputationRank,
    PostsRank
FROM 
    TopUsersPosts
WHERE 
    ReputationRank <= 10 OR PostsRank <= 10
ORDER BY 
    ReputationRank, PostsRank;

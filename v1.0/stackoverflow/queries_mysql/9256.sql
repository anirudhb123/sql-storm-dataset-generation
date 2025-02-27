
WITH UserReputation AS (
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
        Votes V ON P.Id = V.PostId
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
        @rank := IF(@prev_reputation = Reputation, @rank, @rank + 1) AS ReputationRank,
        @prev_reputation := Reputation
    FROM 
        UserReputation, (SELECT @rank := 0, @prev_reputation := NULL) AS vars
    ORDER BY 
        Reputation DESC
)
SELECT 
    T.DisplayName,
    T.Reputation,
    T.TotalPosts,
    T.TotalComments,
    T.TotalUpVotes,
    T.TotalDownVotes,
    (T.TotalUpVotes - T.TotalDownVotes) AS NetVotes
FROM 
    TopUsers T
WHERE 
    T.ReputationRank <= 10
ORDER BY 
    T.Reputation DESC, NetVotes DESC;

-- Performance benchmarking query on Stack Overflow schema
WITH UserRep AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(V.VoteTypeId = 2) AS UpVotes,
        SUM(V.VoteTypeId = 3) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        PostCount,
        CommentCount,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserRep
)
SELECT 
    U.DisplayName,
    U.Reputation,
    T.PostCount,
    T.CommentCount,
    T.UpVotes,
    T.DownVotes,
    T.ReputationRank
FROM 
    TopUsers T
JOIN 
    Users U ON T.UserId = U.Id
WHERE 
    T.ReputationRank <= 10
ORDER BY 
    T.ReputationRank;

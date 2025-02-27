
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(COALESCE(V.VoteCount, 0)) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(Id) AS VoteCount 
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        CommentCount,
        TotalVotes,
        @rn := IF(@prev = Reputation, @rn + 1, 1) AS ReputationRank,
        @prev := Reputation
    FROM 
        UserStats, (SELECT @rn := 0, @prev := NULL) r
    ORDER BY 
        Reputation DESC
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostCount,
    CommentCount,
    TotalVotes
FROM 
    TopUsers
WHERE 
    ReputationRank <= 10;

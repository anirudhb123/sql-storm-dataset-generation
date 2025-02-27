
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(Vote.Value) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        (SELECT 
            V.PostId, 
            CASE 
                WHEN V.VoteTypeId = 2 THEN 1  
                WHEN V.VoteTypeId = 3 THEN -1 
                ELSE 0
            END AS Value
         FROM 
            Votes V) AS Vote ON P.Id = Vote.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.TotalComments,
    U.TotalVotes,
    (@voteRank := @voteRank + 1) AS VoteRank,
    (@postRank := @postRank + 1) AS PostRank
FROM 
    (SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalComments,
        TotalVotes,
        @voteRank := 0
     FROM 
        UserPostStats 
     ORDER BY TotalVotes DESC) AS U,
    (SELECT @postRank := 0) AS ranks
ORDER BY 
    U.TotalPosts DESC, U.TotalVotes DESC;

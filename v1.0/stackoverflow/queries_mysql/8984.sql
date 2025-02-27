
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 0
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        UpVotes,
        DownVotes,
        @rank := @rank + 1 AS Rank
    FROM 
        UserReputation, (SELECT @rank := 0) AS r
    ORDER BY 
        Reputation DESC
)
SELECT 
    T.DisplayName,
    T.Reputation,
    T.TotalPosts,
    T.UpVotes,
    T.DownVotes,
    COALESCE(AVG(P.ViewCount), 0) AS AverageViewCount,
    COALESCE(AVG(P.Score), 0) AS AverageScore
FROM 
    TopUsers T
LEFT JOIN 
    Posts P ON T.UserId = P.OwnerUserId
WHERE 
    T.Rank <= 10
GROUP BY 
    T.UserId, T.DisplayName, T.Reputation, T.TotalPosts, T.UpVotes, T.DownVotes
ORDER BY 
    T.Rank;


WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    GROUP BY 
        U.Id, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        PostCount,
        CommentCount,
        @row_number := @row_number + 1 AS Ranking
    FROM 
        UserReputation, (SELECT @row_number := 0) AS init
    ORDER BY 
        Reputation DESC
)
SELECT 
    U.DisplayName,
    U.Reputation,
    T.PostCount,
    T.CommentCount
FROM 
    TopUsers T
JOIN 
    Users U ON T.UserId = U.Id
WHERE 
    T.Ranking <= 10 
ORDER BY 
    T.Ranking;

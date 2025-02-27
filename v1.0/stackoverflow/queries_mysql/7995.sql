
WITH UserStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        COUNT(DISTINCT P.Id) AS TotalPosts, 
        COUNT(DISTINCT C.Id) AS TotalComments, 
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
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
        TotalUpvotes, 
        TotalDownvotes,
        @rank := @rank + 1 AS Rank
    FROM 
        UserStats, (SELECT @rank := 0) r
    ORDER BY 
        Reputation DESC
)
SELECT 
    T.UserId, 
    T.DisplayName, 
    T.Reputation, 
    T.TotalPosts, 
    T.TotalComments, 
    T.TotalUpvotes, 
    T.TotalDownvotes
FROM 
    TopUsers T
WHERE 
    T.Rank <= 10
ORDER BY 
    T.TotalPosts DESC, T.Reputation DESC;

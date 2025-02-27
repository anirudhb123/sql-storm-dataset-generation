WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostsCreated,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(V.VoteTypeId = 2) AS Upvotes,
        SUM(V.VoteTypeId = 3) AS Downvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostsCreated,
        Questions,
        Answers,
        Upvotes,
        Downvotes,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserStats
    WHERE 
        Reputation > 0
)
SELECT 
    TU.Rank,
    TU.DisplayName,
    TU.Reputation,
    TU.PostsCreated,
    TU.Questions,
    TU.Answers,
    TU.Upvotes,
    TU.Downvotes
FROM 
    TopUsers TU
WHERE 
    TU.Rank <= 10
ORDER BY 
    TU.Rank;

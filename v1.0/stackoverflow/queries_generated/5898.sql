WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS TotalClosedPosts,
        SUM(V.VoteTypeId = 2) AS TotalUpvotes,
        SUM(V.VoteTypeId = 3) AS TotalDownvotes
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
        TotalPosts, 
        TotalQuestions, 
        TotalAnswers, 
        TotalClosedPosts, 
        TotalUpvotes, 
        TotalDownvotes,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserStats
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.TotalPosts,
    TU.TotalQuestions,
    TU.TotalAnswers,
    TU.TotalClosedPosts,
    TU.TotalUpvotes,
    TU.TotalDownvotes,
    PT.Name AS PostTypeName,
    COUNT(P.Id) AS PostCount,
    AVG(P.Score) AS AverageScore
FROM 
    TopUsers TU
JOIN 
    Posts P ON TU.UserId = P.OwnerUserId
JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
GROUP BY 
    TU.UserId, PT.Id
ORDER BY 
    TU.Reputation DESC, PostCount DESC
LIMIT 10;

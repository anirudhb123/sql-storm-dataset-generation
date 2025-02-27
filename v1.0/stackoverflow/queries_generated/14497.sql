-- Performance Benchmarking SQL Query

WITH UsersStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(V.BountyAmount) AS TotalBounty,
        SUM(COALESCE(C.CommentCount, 0)) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalBounty,
        TotalComments,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC) AS Rank
    FROM 
        UsersStats
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalBounty,
    TotalComments
FROM 
    TopUsers
WHERE 
    Rank <= 10;  -- Adjust the number to benchmark different top users based on post count

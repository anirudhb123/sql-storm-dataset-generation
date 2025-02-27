
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalComments,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8  
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalComments,
        TotalBounty,
        @rank := @rank + 1 AS Rank
    FROM UserActivity, (SELECT @rank := 0) r
    ORDER BY TotalPosts DESC, TotalBounty DESC
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalComments,
    TotalBounty
FROM TopUsers
WHERE Rank <= 10
ORDER BY TotalBounty DESC, TotalPosts DESC;

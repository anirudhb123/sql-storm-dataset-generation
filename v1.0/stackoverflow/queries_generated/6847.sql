WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 3 THEN 1 ELSE 0 END) AS TotalWikis,
        SUM(CASE WHEN P.PostTypeId = 2 AND P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(COALESCE(CMT.CommentCount, 0)) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) CMT ON CMT.PostId = P.Id
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserStatistics
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    U.TotalWikis,
    U.AcceptedAnswers,
    U.TotalComments,
    RANK() OVER (ORDER BY U.TotalPosts DESC) AS PostsRank
FROM 
    TopUsers U
WHERE 
    U.ReputationRank <= 10 OR U.PostsRank <= 10
ORDER BY 
    U.Reputation DESC, U.TotalPosts DESC;

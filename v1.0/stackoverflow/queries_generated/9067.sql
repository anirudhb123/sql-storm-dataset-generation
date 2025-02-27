WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN PT.Name = 'Answer' THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN PT.Name = 'Question' THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
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
        TotalAnswers,
        TotalQuestions,
        TotalBadges,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserStatistics
)
SELECT 
    T.DisplayName,
    T.Reputation,
    T.TotalPosts,
    T.TotalComments,
    T.TotalAnswers,
    T.TotalQuestions,
    T.TotalBadges
FROM 
    TopUsers T
WHERE 
    T.ReputationRank <= 10
ORDER BY 
    T.Reputation DESC;

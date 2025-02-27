WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalAnswers,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS TotalQuestions
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId, DisplayName, Reputation, TotalPosts, PositiveScorePosts, TotalAnswers, TotalQuestions,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserReputation
    WHERE 
        Reputation > 1000
),
HighScorers AS (
    SELECT 
        UserId, DisplayName, Reputation, TotalPosts, PositiveScorePosts, TotalAnswers, TotalQuestions
    FROM 
        TopUsers
    WHERE 
        ReputationRank <= 10
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(HP.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(HP.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(PH.PostCount, 0) AS PostHistoryCount,
    COUNT(DISTINCT C.Id) AS TotalComments
FROM 
    HighScorers U
LEFT JOIN (
    SELECT 
        PH.UserId,
        COUNT(*) AS PostCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11, 13)  -- closed, reopened, undeleted
    GROUP BY 
        PH.UserId
) HP ON U.UserId = HP.UserId
LEFT JOIN Comments C ON U.UserId = C.UserId
WHERE 
    U.TotalPosts > 5
GROUP BY 
    U.DisplayName, U.Reputation, HP.TotalQuestions, HP.TotalAnswers, PH.PostCount
ORDER BY 
    U.Reputation DESC, U.DisplayName ASC;

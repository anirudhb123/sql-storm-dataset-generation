WITH RecursiveUserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        1 AS ActivityLevel
    FROM 
        Users U
    WHERE 
        U.CreationDate < NOW() - INTERVAL '1 year'

    UNION ALL

    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        RA.ActivityLevel + 1 AS ActivityLevel
    FROM 
        Users U
    INNER JOIN 
        RecursiveUserActivity RA ON U.Id = RA.UserId
    WHERE 
        U.LastAccessDate > NOW() - INTERVAL '1 month'
),

PostActivity AS (
    SELECT 
        P.OwnerUserId AS UserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),

UserPosts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(PA.TotalPosts, 0) AS TotalPosts,
        COALESCE(PA.TotalQuestions, 0) AS TotalQuestions,
        COALESCE(PA.TotalAnswers, 0) AS TotalAnswers,
        RRA.ActivityLevel
    FROM 
        Users U
    LEFT JOIN 
        PostActivity PA ON U.Id = PA.UserId
    LEFT JOIN 
        RecursiveUserActivity RRA ON U.Id = RRA.UserId
)

SELECT 
    U.DisplayName,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    U.ActivityLevel,
    CASE 
        WHEN U.Reputation > 1000 THEN 'Elite User'
        WHEN U.Reputation BETWEEN 500 AND 1000 THEN 'Regular User'
        ELSE 'New User'
    END AS UserCategory
FROM 
    UserPosts U
WHERE 
    U.TotalPosts > 5
    OR (U.TotalQuestions > 2 AND U.ActivityLevel = 1)
ORDER BY 
    U.TotalPosts DESC, U.ActivityLevel DESC;

-- The query selects users along with their post statistics and categorizes them based on their reputation and activity level. 
-- It employs recursive CTEs to assess user activity, aggregates post data, 
-- and includes a conditional logic for the user categorization based on reputation.

WITH RecursiveUserStats AS (
    -- CTE to calculate cumulative views and scores for users
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        U.CreationDate,
        U.LastAccessDate,
        U.Location,
        U.AboutMe,
        0 AS TotalViews,
        0 AS TotalScore,
        1 AS Level
    FROM Users U
    WHERE U.Id IS NOT NULL
    
    UNION ALL
    
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        U.CreationDate,
        U.LastAccessDate,
        U.Location,
        U.AboutMe,
        R.TotalViews + U.Views,
        R.TotalScore + COALESCE((SELECT SUM(Score) FROM Posts WHERE OwnerUserId = U.Id), 0),
        R.Level + 1
    FROM Users U
    INNER JOIN RecursiveUserStats R ON U.Id = R.UserId
    WHERE R.Level < 2  -- Limit recursion to 2 levels for performance
),

PostScoreAverage AS (
    -- CTE to calculate average scores for posts
    SELECT
        P.OwnerUserId AS UserId,
        AVG(P.Score) AS AvgPostScore
    FROM Posts P
    WHERE P.Score IS NOT NULL
    GROUP BY P.OwnerUserId
),

PostStats AS (
    -- Getting post aggregates, categorizing by accepted answers
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 END) AS AcceptedAnswers,
        COUNT(P.Id) AS TotalPosts,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM Posts P
    WHERE P.OwnerUserId IS NOT NULL
    GROUP BY P.OwnerUserId
)

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COALESCE(R.TotalViews, 0) AS CumulativeViews,
    COALESCE(R.TotalScore, 0) AS CumulativeScore,
    COALESCE(PA.AvgPostScore, 0) AS AveragePostScore,
    COALESCE(PS.AcceptedAnswers, 0) AS AcceptedAnswers,
    COALESCE(PS.TotalPosts, 0) AS TotalPosts,
    CASE 
        WHEN COALESCE(PS.TotalPosts, 0) > 0 THEN (COALESCE(PS.TotalScore, 0) / COALESCE(PS.TotalPosts, 1))
        ELSE 0 
    END AS AverageScorePerPost
FROM Users U
LEFT JOIN RecursiveUserStats R ON U.Id = R.UserId
LEFT JOIN PostScoreAverage PA ON U.Id = PA.UserId
LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
WHERE U.Reputation > 100
  AND U.AccountId IS NOT NULL
ORDER BY CumulativeScore DESC, CumulativeViews DESC;

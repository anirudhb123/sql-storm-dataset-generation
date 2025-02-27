WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT B.Id) AS TotalBadges
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalBounty,
        TotalPosts,
        TotalBadges,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserStats
    WHERE Reputation > 1000
),
PostAnalytics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS AnswersCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount,
        MAX(P.CreationDate) AS MostRecentPost
    FROM Posts P
    WHERE P.PostTypeId = 2 AND P.OwnerUserId IS NOT NULL
    GROUP BY P.OwnerUserId
)
SELECT 
    U.DisplayName AS UserName,
    U.Reputation,
    U.TotalBounty,
    T.TotalPosts,
    T.TotalBadges,
    COALESCE(PA.AnswersCount, 0) AS AnswerCount,
    COALESCE(PA.TotalScore, 0) AS TotalScore,
    COALESCE(PA.AvgViewCount, 0) AS AvgViewCount,
    U.ReputationRank
FROM TopUsers U
LEFT JOIN PostAnalytics PA ON U.UserId = PA.OwnerUserId
ORDER BY U.ReputationRank
LIMIT 10;

SELECT 
    P.Title,
    P.CreationDate,
    COUNT(C.Id) AS CommentCount
FROM Posts P
LEFT JOIN Comments C ON P.Id = C.PostId
WHERE P.PostTypeId = 1 AND P.CreationDate >= (CURRENT_DATE - INTERVAL '30 days')
GROUP BY P.Id
HAVING COUNT(C.Id) > 5
ORDER BY COUNT(C.Id) DESC
LIMIT 5;

SELECT 
    CASE 
        WHEN U.Reputation >= 10000 THEN 'High Achiever'
        WHEN U.Reputation >= 5000 THEN 'Intermediate'
        ELSE 'Newcomer' 
    END AS UserCategory,
    COUNT(DISTINCT U.Id) AS UserCount
FROM Users U
GROUP BY UserCategory
ORDER BY UserCategory DESC;
